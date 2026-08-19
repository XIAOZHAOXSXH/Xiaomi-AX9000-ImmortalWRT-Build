# AX9000 LAN Prefix and Mesh Loop Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Preserve the `192.168.3.9/24` LAN address and make the bundled EasyMesh setup select the actual LAN bridge while enabling layered loop prevention for wired-plus-wireless AX9000 mesh deployments.

**Architecture:** Keep the address override in the existing first-boot UCI script. Apply a checked-in patch to the `kiddin9` EasyMesh package during the Action build so the user explicitly selects the one bridge that carries untagged `bat0`, with BLA and bridge STP enabled. Add build-time assertions and documentation for the one-L2-domain-per-bridge requirement.

**Tech Stack:** OpenWrt/ImmortalWrt UCI, `batman-adv`, shell/`rc.common`, GitHub Actions, POSIX shell static checks.

---

### Task 1: Restore the management prefix

**Files:**
- Modify: `files/etc/uci-defaults/99-xiaomi-ax9000`
- Modify: `README.md`

**Step 1:** Change the first-boot override to `192.168.3.9/24`.

**Step 2:** Update the documented first-boot address to include `/24`.

**Step 3:** Run `sh -n` and search the tree to confirm no bare override remains.

### Task 2: Harden EasyMesh bridge selection and loop prevention

**Files:**
- Create: `patches/luci-app-easymesh-lan-bridge-loop.patch`
- Modify: `.github/workflows/build.yml`

**Step 1:** Patch the feed UI and init script to select one bridge explicitly, resolve both named and anonymous bridge sections without `@device[0]`, repair legacy invalid values such as `"br-lan bat0 bat0"`, remove stale `bat0` membership before adding it, and set bridge `stp=1`.

**Step 2:** Make `network.bat0.bridge_loop_avoidance=1` and bridge membership idempotent even when `bat0` already exists.

**Step 3:** Apply the patch after feed installation and assert the patched script contains the required selectors/settings before building.

**Step 4:** Run a mocked UCI test covering named and anonymous bridge sections, multi-bridge cleanup, idempotent target membership, legacy-value migration, and fail-closed handling for non-bridge devices.

**Step 5:** Pin the `kiddin9` feed to the verified revision so the checked-in patch has a stable source baseline.

### Task 3: Verify and deliver

**Files:**
- Modify: `.config` (only if needed to explicitly retain `CONFIG_BATMAN_ADV_BLA=y`)

**Step 1:** Run shell syntax checks, `git diff --check`, and a patch dry-run against the audited feed revision.

**Step 2:** Inspect the final diff and ensure only intended files are staged.

**Step 3:** Commit with the requested temporary author identity and push the current branch to `origin`.
