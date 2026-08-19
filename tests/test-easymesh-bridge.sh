#!/bin/sh

set -eu

[ "$#" -eq 1 ] || {
	echo "usage: $0 PATH_TO_EASYMESH_INIT" >&2
	exit 2
}

easymesh_init=$1
[ -f "$easymesh_init" ] || {
	echo "missing EasyMesh init script: $easymesh_init" >&2
	exit 2
}

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
command_log=$test_dir/uci-commands
expected=$test_dir/expected
: >"$command_log"

uci() {
	[ "${1:-}" = "-q" ] && shift
	operation=${1:-}
	argument=${2:-}

	case "$operation:$argument" in
		show:network)
			cat <<-'EOF'
			network.@device[0]=device
			network.@device[0].name='br-guest'
			network.@device[0].type='bridge'
			network.@device[1]=device
			network.@device[1].name='br-lan'
			network.@device[1].type='bridge'
			network.mesh_lan=device
			network.mesh_lan.name='br-mesh'
			network.mesh_lan.type='bridge'
			network.wan_dev=device
			network.wan_dev.name='wan'
		EOF
			;;
		get:network.@device\[0\].name) printf '%s\n' 'br-guest' ;;
		get:network.@device\[0\].type) printf '%s\n' 'bridge' ;;
		get:network.@device\[1\].name) printf '%s\n' 'br-lan' ;;
		get:network.@device\[1\].type) printf '%s\n' 'bridge' ;;
		get:network.mesh_lan.name) printf '%s\n' 'br-mesh' ;;
		get:network.mesh_lan.type) printf '%s\n' 'bridge' ;;
		get:network.wan_dev.name) printf '%s\n' 'wan' ;;
		get:network.wan_dev.type) return 1 ;;
		del_list:*|set:*|add_list:*)
			printf '%s %s\n' "$operation" "$argument" >>"$command_log"
			;;
		*) return 1 ;;
	esac
}

. "$easymesh_init"

mesh_bridge=br-lan
[ "$(find_mesh_bridge)" = '@device[1]' ]
configure_mesh_bridge

cat >"$expected" <<-'EOF'
del_list network.@device[0].ports=bat0
del_list network.@device[1].ports=bat0
del_list network.mesh_lan.ports=bat0
set network.@device[1].stp=1
add_list network.@device[1].ports=bat0
EOF

cmp -s "$expected" "$command_log" || {
	diff -u "$expected" "$command_log" >&2 || true
	exit 1
}

: >"$command_log"
mesh_bridge=br-mesh
[ "$(find_mesh_bridge)" = 'mesh_lan' ]
configure_mesh_bridge
grep -Fqx 'set network.mesh_lan.stp=1' "$command_log"
grep -Fqx 'add_list network.mesh_lan.ports=bat0' "$command_log"

: >"$command_log"
lan_device='br-lan bat0 bat0'
mesh_bridge=
repair_legacy_lan_device
[ "$lan_device" = 'br-lan' ]
[ "$mesh_bridge" = 'br-lan' ]
grep -Fqx 'set network.lan.device=br-lan' "$command_log"

load_line=$(grep -n '^[[:space:]]*load_easymesh_config$' "$easymesh_init" | cut -d: -f1)
repair_line=$(grep -n '^[[:space:]]*repair_legacy_lan_device$' "$easymesh_init" | cut -d: -f1)
branch_line=$(grep -n '^[[:space:]]*if \[ "$enable" = 1 \]; then$' "$easymesh_init" | cut -d: -f1)
[ "$load_line" -lt "$repair_line" ]
[ "$repair_line" -lt "$branch_line" ]

: >"$command_log"
mesh_bridge=wan
if configure_mesh_bridge 2>/dev/null; then
	echo 'a non-bridge LAN device was accepted' >&2
	exit 1
fi
[ ! -s "$command_log" ]

: >"$command_log"
mesh_bridge=
if configure_mesh_bridge 2>/dev/null; then
	echo 'an empty LAN device was accepted' >&2
	exit 1
fi
[ ! -s "$command_log" ]
