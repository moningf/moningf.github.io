---
title: 'Mihomo TUN 与 Tailscale 共存：Fake-IP 登录故障排查'
publishDate: '2026-09-10T00:00:00+08:00'
description: '记录一次 Mihomo TUN 与 Tailscale 共存时的登录故障：DNS 返回 Fake-IP，而 tailscaled 绕过 TUN，最终导致连接超时。'
tags:
  - Linux
  - Mihomo
  - Tailscale
  - Clash Verge Rev
language: '中文'
draft: false
---

最近在 Arch Linux 上同时开了 Clash Verge Rev 的 TUN 模式和 Tailscale。本来的想法很简单：普通流量交给 Mihomo，Tailnet 内的流量继续走 `tailscale0`。结果重启后，Tailscale 一直登录不上，MagicDNS 也跟着失效。

配置中已经排除了 `100.64.0.0/10`，重启后 Tailscale 仍然无法登录。日志显示，Mihomo 给 Tailscale 的域名返回了 Fake-IP，`tailscaled` 随后绕过 Mihomo，从物理网卡直接连接这个地址。DNS 和后续连接走了两条不同的路，最后连接超时。

## 结论

需要同时处理两件事：

```yaml
dns:
  fake-ip-filter:
    - '+.tailscale.com'
    - '+.tailscale.io'

tun:
  route-exclude-address:
    - 100.64.0.0/10
```

- `fake-ip-filter` 让 Tailscale 的公网服务域名返回真实 IP，解决登录阶段的超时；
- `route-exclude-address` 避免登录后的 Tailnet 和 MagicDNS 流量被 Mihomo 抢走。

两项配置分别处理登录阶段和登录后的 Tailnet 流量，需要同时保留。

## 当时的环境

- Arch Linux
- Clash Verge Rev（Mihomo 内核）
- Mihomo TUN 模式，DNS 使用 Fake-IP
- Tailscale
- `systemd-resolved`
- 物理网卡：`wlp8s0`
- Mihomo 虚拟网卡：`Mihomo`
- Tailscale 虚拟网卡：`tailscale0`

Mihomo 分配的 Fake-IP 位于 `198.18.0.0/16`。

## 现象：Tailscale 卡在登录阶段

重启后，先跟踪一下 `tailscaled` 的日志：

```bash
journalctl -u tailscaled -f
```

其中最显眼的是这条：

```text
logtail: dial "log.tailscale.com:443" failed:
dial tcp 198.18.0.35:443: i/o timeout
```

`198.18.0.35` 一看就是 Mihomo 分配的 Fake-IP。日志里还能看到 Tailscale 尝试使用 Bootstrap DNS 找到真实地址：

```text
trying bootstrapDNS(...) for "log.tailscale.com" ...
bootstrapDNS(...) = [真实公网 IPv4/IPv6 地址]
logtail: bootstrap dial succeeded
```

有些控制服务器请求偶尔能成功，注册请求仍然持续超时：

```text
register request: Post "https://controlplane.tailscale.com/machine/register":
connection attempts aborted by context: context deadline exceeded
```

再看 `tailscale0` 的 DNS 状态：

```bash
resolvectl status tailscale0
```

当时的输出大致是这样：

```text
Link 4 (tailscale0)
    Current Scopes: LLMNR/IPv6 mDNS/IPv6
         Protocols: -DefaultRoute +LLMNR +mDNS -DNSOverTLS DNSSEC=no/unsupported
     Default Route: no
```

这里既没有 DNS scope，也没有 `DNS Servers: 100.100.100.100` 和 Tailnet 对应的 routing domain。换句话说，Tailscale 还没登录成功，自然也没机会向 `systemd-resolved` 注册 MagicDNS。

## 排除 Tailscale 网段后仍然无法登录

Tailscale 的设备地址通常来自 `100.64.0.0/10`，MagicDNS 使用的 `100.100.100.100` 也在这个范围内。最先尝试的配置是：

```yaml
tun:
  enable: true
  auto-route: true
  route-exclude-address:
    - 100.64.0.0/10
```

这项配置的作用是：目标地址属于 `100.64.0.0/10` 时，不进入 Mihomo 创建的 TUN 路由，继续交给系统的其他路由规则处理。登录成功后，Tailnet 流量就可以命中 Tailscale 自己的路由，从 `tailscale0` 发出。

这项配置只影响目标为 Tailnet 地址的流量。登录阶段访问的是下面这些公网域名：

```text
controlplane.tailscale.com
log.tailscale.com
derp*.tailscale.com
```

这些域名会解析到公网地址，排除 Tailnet 网段对控制平面连接没有作用。

## 控制平面域名返回了 Fake-IP

直接查询控制平面域名：

```bash
resolvectl query controlplane.tailscale.com
```

或者：

```bash
nslookup controlplane.tailscale.com
```

返回的是 `198.18.0.x`。这说明 DNS 查询已经被 Mihomo 接管，并为这个域名分配了 Fake-IP。

这里还有一个容易忽略的问题：`nslookup` 后面应该传主机名，不能传完整 URL。正确写法是：

```bash
nslookup controlplane.tailscale.com
```

下面这种写法无法得到正确结果：

```bash
nslookup https://controlplane.tailscale.com/machine/register
```

## Fake-IP 的工作方式

Fake-IP 是 Mihomo 使用的内部映射地址，对应关系保存在 Mihomo 中。正常流程是：

```text
应用查询 example.com
  → Mihomo 返回 198.18.0.10
  → 应用连接 198.18.0.10:443
  → 连接再次进入 Mihomo TUN
  → Mihomo 找回原域名并匹配规则
  → 连接真实服务器
```

关键是连接必须再次进入 Mihomo TUN。只要 DNS 由 Mihomo 返回了 Fake-IP，后续连接就必须回到同一个 Mihomo 实例。否则，`198.18.x.x` 只会被当成普通目标地址发出去，最终连接超时。

浏览器等普通程序拿到 Fake-IP 后，连接会再次进入 Mihomo。`tailscaled` 的连接携带 bypass mark，出口路径发生了变化。

## 用抓包确认流量到底去了哪里

为了确认 `tailscaled` 连接 Fake-IP 时经过哪个接口，可以监听所有接口的出站流量：

```bash
sudo tcpdump -ni any -Q out -nn -vv \
  'dst net 198.18.0.0/16 and tcp dst port 443'
```

然后在另一个终端重启 Tailscale：

```bash
sudo systemctl restart tailscaled
journalctl -u tailscaled -f
```

按 Fake-IP 的工作方式，目标为 `198.18.0.35:443` 的数据包应该出现在 Mihomo 网卡上。抓包记录显示它出现在 `wlp8s0`：

```text
wlp8s0 Out IP ... > 198.18.0.35.443
```

也可以分别监听两个接口，结果会更直观：

```bash
sudo tcpdump -ni Mihomo -nn \
  'dst net 198.18.0.0/16 and tcp dst port 443'

sudo tcpdump -ni wlp8s0 -nn \
  'dst net 198.18.0.0/16 and tcp dst port 443'
```

抓包结果显示：DNS 进入了 Mihomo，`tailscaled` 建立 TCP 连接时绕过 Mihomo，直接把 Fake-IP 发到了物理网卡。

## `tailscaled` 为什么能绕过 TUN

Linux 在选路时会同时参考目标地址和数据包上的 `fwmark`，不同的 mark 可以指向不同的路由表。

Mihomo 开启 `auto-route` 后，通常会创建自己的策略路由。例如普通流量经过 `ip rule` 后，查询 Mihomo 使用的路由表，再进入 TUN。

Tailscale 需要避免控制连接再次进入 VPN，以免形成路由循环。它会给自己的连接设置 bypass mark；在 Linux 上通常通过 `SO_MARK` 实现，必要时也可以绑定默认出口网卡。带有这个 mark 的连接会优先查询系统主路由表，并从物理网卡发出。

先查看当前规则：

```bash
ip rule show
```

如果能看到类似规则：

```text
from all fwmark 0x80000/0xff0000 lookup main
```

可以对比普通数据包和带 mark 数据包的路由结果：

```bash
ip route get 198.18.0.35
sudo ip route get 198.18.0.35 mark 0x80000
```

结果可能分别是：

```text
198.18.0.35 dev Mihomo table 2022
```

以及：

```text
198.18.0.35 via <网关地址> dev wlp8s0 table main mark 0x80000
```

完整的故障链路如下：

```text
tailscaled 查询控制平面域名
  → Mihomo DNS 返回 198.18.x.x
  → tailscaled 发起 HTTPS 连接
  → bypass mark 让连接绕过 Mihomo TUN
  → Fake-IP 被直接发到物理网卡
  → 连接超时，Tailscale 无法登录
```

`systemd-resolved` 在整个过程中工作正常。它负责接收查询、缓存结果和按 routing domain 选择 DNS 上游。DNS 数据包离开它之后，依然可能被 TUN 路由或 `dns-hijack` 接管。启用 `systemd-resolved` 无法自动隔离 Mihomo DNS 和 Tailscale DNS。

## 解决登录问题：让 Tailscale 域名返回真实 IP

既然 `tailscaled` 的公网连接本来就会绕过 Mihomo，那么相关域名就不能再使用依赖 Mihomo 回流的 Fake-IP。

在 Clash Verge Rev 的 DNS 覆写或合并配置里，把下面两项加进现有的 `fake-ip-filter`：

```yaml
dns:
  fake-ip-filter:
    - '+.tailscale.com'
    - '+.tailscale.io'
```

这两项应当合并到原有列表，不要把订阅自带的 `fake-ip-filter` 整段覆盖掉。

如果使用的是 `fake-ip-filter-mode: rule`，可以这样写：

```yaml
dns:
  fake-ip-filter-mode: rule
  fake-ip-filter:
    - DOMAIN-SUFFIX,tailscale.com,real-ip
    - DOMAIN-SUFFIX,tailscale.io,real-ip
    - MATCH,fake-ip
```

应用配置并重启 Mihomo 内核后，清掉 `systemd-resolved` 的缓存：

```bash
sudo resolvectl flush-caches
```

再查一次：

```bash
resolvectl query controlplane.tailscale.com
resolvectl query log.tailscale.com
```

这次应该直接返回真实公网 IP。`tailscaled` 继续绕过 TUN，也能连接到正确的服务器。

## 登录后：保留 Tailscale 网段排除

`fake-ip-filter` 只解决公网控制连接，登录后的 Tailnet 流量仍然需要交给 Tailscale，所以 `100.64.0.0/10` 的排除项也要保留：

```yaml
tun:
  enable: true
  auto-route: true
  route-exclude-address:
    - 100.64.0.0/10
```

这个网段包含 Tailscale 设备地址，也包含 MagicDNS 使用的 `100.100.100.100`。排除后，相关流量会跳过 Mihomo，继续匹配 Tailscale 创建的路由。

`route-exclude-address` 只让这段流量跳过 Mihomo。后续出口仍由系统路由决定，可能是 `wlp8s0`、其他物理网卡，也可能是 `tailscale0`。

## 恢复 MagicDNS

Tailscale 登录成功后，如果需要使用 MagicDNS，先允许它向系统注册 DNS 配置：

```bash
sudo tailscale set --accept-dns=true
```

然后检查：

```bash
resolvectl status tailscale0
```

正常情况下可以看到类似内容：

```text
Link (tailscale0)
    Current Scopes: DNS
    DNS Servers: 100.100.100.100
    DNS Domain: ~<tailnet-name>.ts.net
```

这时，Tailnet 域名会由 `systemd-resolved` 根据 routing domain 发给 `100.100.100.100`。由于这个地址已经被排除在 Mihomo TUN 之外，查询会继续由 Tailscale 处理，最终返回设备的 `100.64.x.x` 地址。

## 最后做一轮检查

### 1. 公网服务域名不再返回 Fake-IP

```bash
resolvectl query controlplane.tailscale.com
resolvectl query log.tailscale.com
```

结果不应该是 `198.18.x.x`。

### 2. Tailscale 已经登录

```bash
tailscale status
```

不应该再出现 logged out 或控制平面连接超时。

### 3. MagicDNS 已注册到系统

```bash
resolvectl status tailscale0
```

确认存在 `DNS Servers: 100.100.100.100` 和 Tailnet 对应的 DNS domain。

### 4. Tailnet 域名返回 Tailscale 地址

```bash
resolvectl query <设备名>.<tailnet-name>.ts.net
```

结果应该位于 `100.64.0.0/10`。如果仍然得到 Fake-IP，说明 MagicDNS 查询没有走 `tailscale0`。

### 5. 设备流量进入 Tailscale

```bash
ip route get <设备的 100.64.x.x 地址>
```

结果应该指向 Tailscale 的路由规则或 `tailscale0`。如果指向 Mihomo，需要继续检查 TUN 的排除配置。

## 几个配置细节

### `DIRECT` 与路由排除的处理位置不同

Mihomo 的 `DIRECT` 作用于已经进入 Mihomo 的流量，由 Mihomo 建立直连。`route-exclude-address` 在路由阶段跳过 Mihomo。Tailnet 虚拟网段适合使用后者，继续保留 Tailscale 的原生路由。

### 不要排除 Fake-IP 网段

不要把 `198.18.0.0/16` 加入 TUN 排除列表。普通程序拿到 Fake-IP 后，必须通过这个地址重新进入 Mihomo；排除后，其他 Fake-IP 连接也会一起失效。

### Fake-IP 依赖完整的回流路径

DNS 查询进入 Mihomo，后续连接绕开 Mihomo，最终导致 Fake-IP 映射无法生效。

## 总结

Tailscale 登录时访问公网控制平面，此时还没有用到 Tailnet 私有地址。Mihomo 为控制平面域名返回 Fake-IP 后，`tailscaled` 又通过 bypass mark 绕开 Mihomo，连接最终超时。`100.64.0.0/10` 的路由排除负责登录后的 Tailnet 流量，无法影响这段登录流程。

排查多 TUN/VPN 共存问题时，需要分别确认 DNS 返回值、策略路由和连接的实际出口。`journalctl`、`resolvectl`、`ip rule`、`ip route get` 和 `tcpdump` 基本可以把这几段路径还原出来。

## 参考资料

- [Mihomo TUN 配置文档](https://wiki.metacubex.one/config/inbound/tun/)
- [Mihomo DNS 配置文档](https://wiki.metacubex.one/config/dns/)
- [Tailscale Linux 套接字绕行实现](https://github.com/tailscale/tailscale/blob/main/net/netns/netns_linux.go)
- [Tailscale DNS 文档](https://tailscale.com/docs/reference/dns-in-tailscale)
- [systemd-resolved 与 VPN Split DNS](https://systemd.io/RESOLVED-VPNS/)
