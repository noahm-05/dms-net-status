# Network Status

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) bar widget that shows your local machine IP, active VPN tunnel IP, and (optionally) your Tailscale IP — built for keeping connectivity visible during HTB labs and other pentest lab work.

## Features

- Bar pill shows **one address at a time** — **right-click the widget to cycle** through Local, VPN, and Tailscale
- Turns red and says "VPN off" the instant your tunnel drops, so a dropped lab connection is impossible to miss
- Left-click opens a popout listing every address at once, with copy-to-clipboard buttons and a manual refresh
- VPN detection reads network interfaces directly (`ip -j addr show`), so it works whether the tunnel came up via `openvpn`, `wg-quick`, or NetworkManager
- Tailscale support reuses DMS's own `TailscaleService` — no extra process spawned
- The last-selected bar address persists across shell restarts

## Installation

### Manually

```bash
cd ~/.config/DankMaterialShell/plugins
git clone https://github.com/noahm-05/dms-net-status NetStatus
```

Then in DMS Settings → Plugins, click "Scan for Plugins" and enable **Network Status**. Add it to a bar section from Settings → DankBar.

### Via DMS CLI (once available in the registry)

```bash
dms plugins install netStatus
```

## Usage

- **Left-click** the bar widget to open the popout with all addresses.
- **Right-click** the bar widget to cycle what's shown: Local → VPN → Tailscale (if enabled) → back to Local.
- Click the copy icon on any row in the popout to copy that address to your clipboard.
- Click the refresh icon next to the popout's close button to re-check interfaces immediately.

## Settings

- **Refresh Interval** — how often to re-check interfaces (default 5s)
- **Compact Mode** — icon only in the bar, no IP text
- **Include Tailscale** — adds Tailscale to the right-click rotation and its own popout row
- **VPN Interface Prefixes** — comma-separated interface name prefixes treated as VPN tunnels (default `tun,wg,ppp,tap`)
- **Excluded Interface Prefixes** — comma-separated prefixes ignored entirely, e.g. Docker/virtual bridges (default `docker,veth,br-,virbr`)

## How VPN/local detection works

Every poll interval, the plugin runs `ip -j addr show` and classifies interfaces by name prefix:

- Interfaces matching a **VPN prefix** are treated as the VPN tunnel.
- Interfaces matching an **excluded prefix** are ignored (virtual/container bridges, not your real connection).
- Everything else with an IPv4 address is a candidate for "Local IP", preferring interfaces that are `UP`.

Both prefix lists are configurable, so this works whether your lab VPN comes up as `tun0` (OpenVPN, the HTB default) or `wg0` (WireGuard).

## Requirements

- DankMaterialShell
- `iproute2` (the `ip` command with `-j` JSON output support) — present by default on Debian/Parrot
- Tailscale support is optional and just reflects "not available"/"not connected" if `tailscaled` isn't running

## License

MIT
