# OPNSense-Singbox

[![Build OPNsense Plugin](https://github.com/StoneMoe/opnsense-singbox/actions/workflows/build.yml/badge.svg)](https://github.com/StoneMoe/opnsense-singbox/actions/workflows/build.yml)

## Build

Packages are automatically built on push to `master` and on version tags (`v*`).

- **Artifacts**: Available as workflow artifacts for each build
- **Releases**: Created automatically when pushing a version tag (e.g., `v1.0.0`)

## Note

The plugin does not bundle or update proxy binaries. Before enabling it, upload a compatible
`singbox` binary and the extracted `tun2socks-freebsd-amd64` binary from
[xjasonlyu/tun2socks releases](https://github.com/xjasonlyu/tun2socks/releases).

tun2socks setups:
1. setup Device by tun2socks
    --device=tun://proxytun0 --mtu=8500 --proxy=socks5://127.0.0.1:12000 --udp-timeout=120s --tun-post-up='/usr/local/etc/rc.linkup start proxytun0'
2. assign the device with MTU 8500 and addresses `198.18.0.2/15` and `fd00:198:18::2/126`
3. create gateways `198.18.0.1` and `fd00:198:18::1`, with gateway monitoring disabled
4. create firewall rules to route IPv4 and IPv6 traffic to the matching proxy gateway

## Reference

- [OPNsense configd docs](https://docs.opnsense.org/development/backend/configd.html) - `/usr/local/opnsense/service/conf/actions.d/`
- [OPNsense legacy backend](https://docs.opnsense.org/development/backend/legacy.html) - `/usr/local/etc/inc/plugins.inc.d/`
- [OPNsense syshook](https://docs.opnsense.org/development/backend/autorun.html#syshook) - `/usr/local/etc/rc.syshook.d/`
