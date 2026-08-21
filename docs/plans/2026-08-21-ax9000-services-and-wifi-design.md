# AX9000 Services and Wi-Fi Implementation Plan

**Goal:** Produce an AX9000 image with reliable runtime APK repositories, Chinese LuCI packages, web file management, FTP access, scheduled reboot, and a verified QCN9074 160 MHz configuration.

**Architecture:** Keep third-party feeds available during the build, but disable their runtime APK repositories because they are build sources rather than guaranteed public repositories. Build the requested services into the image and add explicit runtime/configuration assertions. For 160 MHz, preserve the QCN9074 board-file overlay and validate the generated wireless configuration and firmware path rather than relying on a filename-only replacement.

**Tech Stack:** ImmortalWrt master, APK, LuCI, Kiddin9 package feed, OpenWrt UCI, ath11k/QCN9074.

---

### Task 1: Runtime package repositories

Modify `.config` and the workflow so package and LuCI repositories remain enabled while `kiddin9`, `ow_packages`, `video`, and other unused feeds are disabled for runtime APK generation. Add assertions that the final generated feed configuration does not contain those disabled repositories.

### Task 2: Built-in services and Chinese LuCI

Add `filebrowser`, `luci-app-filebrowser`, `vsftpd`, `luci-app-vsftpd`, and `luci-app-autoreboot` to the explicit Kiddin9 package links and `.config`. Add the LuCI base, firewall, package-manager, FileBrowser, vsftpd, and autoreboot Chinese translations; assert their config entries survive `make defconfig`. Verify the service files and Chinese translation sources exist before the build.

### Task 3: FTP defaults and file service

Ship the package defaults, keep FTP restricted to the LAN firewall zone, and verify the generated image contains the vsftpd UCI defaults, FileBrowser init script/config, and LuCI menu entries. Do not expose FTP on WAN.

### Task 4: 160 MHz validation

Inspect the QCN9074 board file path and target wireless driver configuration. Add a build-time check for the target's 5 GHz radio path and document the runtime checks (`iw phy`, channel width, country/DFS status). Only change board data or wireless defaults when the source confirms the current file is not the one loaded by ath11k.

### Task 5: Verification and delivery

Run YAML parsing, shell syntax, package-source checks, `git diff --check`, and the EasyMesh regression test. Commit with the requested identity, push to `main`, and verify the new GitHub Actions run reaches `Configure target and packages` and the firmware build.
