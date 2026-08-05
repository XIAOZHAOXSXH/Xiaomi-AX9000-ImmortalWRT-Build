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

The first boot LAN address is `192.168.3.9`. The supplied AX9000 BDF is copied
to `ath11k/QCN9074/hw1.0/board-2.bin`, which is the 5.2 GHz radio path. The
IPQ8074 board file is intentionally left unchanged.

The generated image is published as a GitHub Actions artifact. Use the
`xiaomi_ax9000-stock` sysupgrade image for the stock-layout U-Boot.
