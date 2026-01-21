# OPNSense-Singbox

[![Build OPNsense Plugin](https://github.com/StoneMoe/opnsense-singbox/actions/workflows/build.yml/badge.svg)](https://github.com/StoneMoe/opnsense-singbox/actions/workflows/build.yml)

## Build

Packages are automatically built on push to `master` and on version tags (`v*`).

- **Artifacts**: Available as workflow artifacts for each build
- **Releases**: Created automatically when pushing a version tag (e.g., `v1.0.0`)

## Note
tun2socks setups:
1. setup Device by tun2socks
    -device tun://proxytun0 -mtu 1392 -proxy socks5://127.0.0.1:12000 -udp-timeout 120s
2. assign device to Interface as 198.18.0.2/15
3. setup a gateway as 198.18.0.1
4. create fw rules to forward traffic to proxy gateway

## Reference

- [OPNsense configd docs](https://docs.opnsense.org/development/backend/configd.html) - `/usr/local/opnsense/service/conf/actions.d/`
- [OPNsense legacy backend](https://docs.opnsense.org/development/backend/legacy.html) - `/usr/local/etc/inc/plugins.inc.d/`
- [OPNsense syshook](https://docs.opnsense.org/development/backend/autorun.html#syshook) - `/usr/local/etc/rc.syshook.d/`
