# ImmortalWrt Xiaomi AX9000 build

This repository builds the ImmortalWrt `qualcommax/ipq807x` target using the
`xiaomi_ax9000-stock` profile. It is intended for the Xiaomi AX9000 with the
Dark Cloud U-Boot stock partition layout.

The workflow adds pinned `openwrt/packages` and `kiddin9/op-packages` feeds and
includes:

- OpenClash
- EasyMesh
- Lucky and its LuCI app
- AdvancedPlus
- `luci-proto-batman-adv`
- `kmod-batman-adv`
- `wpad-mbedtls`
- Bootstrap LuCI theme
- FileBrowser web file manager
- vsftpd with LuCI configuration
- Scheduled reboot (LuCI AutoReboot)

The batman-adv kernel module and batctl are taken from the pinned
`openwrt/packages` feed because upstream moved them out of `openwrt/routing`.
Only the explicitly selected Kiddin9 packages used by this image are linked into the build;
this avoids unrelated feed metadata conflicts.

The build also includes Simplified Chinese translations for the LuCI base,
firewall, and package manager pages, and selects Chinese as the first-boot
language. Third-party build feeds are disabled in the runtime APK repository;
their packages are already installed in the image, so `apk update` does not
try to download nonexistent feed indexes.

FileBrowser is installed but disabled by default for security; enable it in its
LuCI page before use. FTP is LAN-only by default and requires a local system
account. The scheduled reboot page is under System and is disabled until a
schedule is configured.

The first boot LAN address is `192.168.3.9/24`. The supplied AX9000 BDF is copied
to `ath11k/QCN9074/hw1.0/board-2.bin`, which is the 5.2 GHz radio path. The
IPQ8074 board file is intentionally left unchanged.

The generated image is published as a GitHub Actions artifact. Use the
`xiaomi_ax9000-stock` sysupgrade image for the stock-layout U-Boot.

## Mesh bridge topology

The build patches EasyMesh with a `MESH LAN bridge` selector and attaches the
untagged `bat0` device only to that bridge. It removes stale `bat0` membership
from other bridges first, enables batman-adv Bridge Loop Avoidance (BLA), and
enables STP on the selected bridge. This protects a two-node mesh when the same
LAN is reachable through both Ethernet and the wireless mesh.

Keep these topology constraints when adding networks in LuCI:

- Put the untagged `bat0` device in exactly one bridge.
- With separate `domestic` and `international` bridges, select the bridge that
  owns the LAN ports (the `domestic` bridge in the pictured topology) as the
  EasyMesh `MESH LAN bridge`.
- Do not assign the same IPv4 subnet, such as `192.168.3.0/24`, to two separate
  bridge interfaces on the same router.
- To carry multiple layer-2 networks over the mesh, use distinct VLANs on
  `bat0` and bridge each VLAN separately. Do not add raw `bat0` to every bridge.

After changing the EasyMesh settings, verify the safeguards with:

```sh
uci -q get network.bat0.bridge_loop_avoidance
batctl meshif bat0 bridge_loop_avoidance
uci show network | grep -E "\.stp=|\.ports='bat0'"
```

The first two commands should report `1` or `enabled`. The final command should
show STP enabled and exactly one bridge containing untagged `bat0`.

For the QCN9074 5 GHz radio, 160 MHz is subject to the regulatory domain, DFS
availability, channel selection, and the client capability. Check the actual
driver state rather than only the LuCI selection:

```sh
iw phy phy1 info | grep -A2 -E '160 MHz|HE160|VHT160'
iw dev phy1-ap0 info
logread | grep -E 'ath11k|board|DFS|regulatory'
```

The AX9000 board file is installed at
`/lib/firmware/ath11k/QCN9074/hw1.0/board-2.bin`; replacing a file under a
different ath11k path does not affect this radio.
