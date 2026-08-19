# ImmortalWrt Xiaomi AX9000 build

This repository builds the ImmortalWrt `qualcommax/ipq807x` target using the
`xiaomi_ax9000-stock` profile. It is intended for the Xiaomi AX9000 with the
Dark Cloud U-Boot stock partition layout.

The workflow adds the `kiddin9/op-packages` feed and includes:

- OpenClash
- EasyMesh
- Lucky and its LuCI app
- AdvancedPlus
- `luci-proto-batman-adv`
- `kmod-batman-adv`
- `wpad-mbedtls`
- Bootstrap LuCI theme

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
