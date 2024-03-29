#! /usr/bin/env bash
set -euo pipefail

conf_dir="${HOME}/.local/VM/snapshots"
prefix="_pre_"


_help() {
  local script_name
  script_name="$(basename -- "$0")"

  printf "%s\n" \
  "${script_name}: create and revert external libvirt snapshots easily" \
  "" \
  "Usage: $script_name <action> <domain> [snapshot name]" \
  "" \
  "" \
  "Actions:" \
  "--------" \
  "create, c           Create snapshot" \
  "                    If no snapshot name is provided, current date and time is used" \
  "" \
  "list, ls, l         List snapshots" \
  "" \
  "disks               Show active disks" \
  "" \
  "revert, rev, r      Revert snapshot and delete it (same as soft-revert + delete)" \
  "" \
  "soft-revert," \
  "srev, sr            Revert snapshot without deleting it (allows unrevert)" \
  "" \
  "unrevert," \
  "unrev, ur           Unrevert snapshot, i.e. make soft-reverted snapshot active again" \
  "" \
  "delete, del, rm     Delete snapshot" \
  "" \
  "help, h             This message" \
  "" \
  "" \
  "Snapshots are created without metadata, so they won't be shown with \`virsh snapshot-list\`"
}

_die() {
  echo "${1}. Exit."
  exit 1
}

_yes_or_no() {
  echo
  local yn
  while true; do
    read -p "$* [ enter + or - ]: " yn < /dev/tty || _die "No tty"
    case "$yn" in
      "+") return 0 ;;
      "-") return 1 ;;
    esac
  done
}

_die_on_auto_name() {
  [ "$auto_name" = false ] || _die "No snapshot name provided"
}

_has_disks() {
  virsh domblklist "$domain" --details | grep -qE 'file\s+disk' || return 1
}

_get_disks_path() {
  virsh domblklist "$domain" --details | grep -E 'file\s+disk' | sed -E 's|[^/]+(.+)|\1|'
}

_create() {
  _has_disks || _die "'${domain}' has no disks, nothing to snapshot"

  local base_conf snap_conf
  base_conf="${domain_conf_dir}/${prefix}${name}.xml"
  snap_conf="${domain_conf_dir}/${name}.xml"

  _get_disks_path | while IFS= read -r base_disk; do
    local snap_disk
    snap_disk="${base_disk%.*}.${name}" # expected
    [ ! -e "$snap_disk" ] || _die "Disk '$snap_disk' already exist"
    [ ! -e "$snap_conf" ] || _die "Snapshot conf '$snap_conf' already exist"

    echo "Base disk: $base_disk"
    echo "Overlay disk: $snap_disk"
  done

  virsh dumpxml "$domain" > "$base_conf"
  virsh snapshot-create-as "$domain" "$name" --disk-only --no-metadata --atomic
  virsh dumpxml "$domain" > "$snap_conf"
}

_list() {
  local f
  shopt -s nullglob
  for f in "${domain_conf_dir}"/*.xml; do
    f="$(basename -- "$f")"
    [ "${f:0:5}" != "_pre_" ] || continue
    echo "${f%.xml}";
  done
  shopt -u nullglob
}

_delete() {
  _die_on_auto_name

  # We could just rm $disk, but after revert it won't point to the right snapshot disk path,
  # so we construct the right path manually
  local snap_conf snap_parent_conf
  snap_conf="${domain_conf_dir}/${name}.xml"
  snap_parent_conf="${domain_conf_dir}/${prefix}${name}.xml"

  _get_disks_path | while IFS= read -r disk; do
    local snap_disk disk_dir sudo_cmd
    snap_disk="${disk%.*}.${name}"
    disk_dir="$(dirname -- "$disk")"
    sudo_cmd=""

    if [ "$disk" = "$snap_disk" ]; then
      echo "Looks like you are deleting snapshot which is currently in use"
      echo "You won't be able to revert if you delete it"
      _yes_or_no "Are you sure?" || return
    fi

    if [ ! -w "$disk_dir" ] || [ ! -x "$disk_dir" ]; then
      sudo_cmd="sudo"
      echo "Root privileges required to remove disk file '$snap_disk'"
    fi

    [ -f "$snap_disk" ] && $sudo_cmd rm "$snap_disk"
  done

  [ -f "$snap_conf" ] && rm "$snap_conf"
  [ -f "$snap_parent_conf" ] && rm "$snap_parent_conf"
}

_soft_revert() {
  _die_on_auto_name
  virsh define "${domain_conf_dir}/${prefix}${name}.xml"
}

_revert() {
  _die_on_auto_name
  _soft_revert
  _delete
}

_unrevert() {
  _die_on_auto_name
  virsh define "${domain_conf_dir}/${name}.xml"
}


[ -n "${1:-}" ] || _die 'No action specified'
[ -n "${2:-}" ] || { _help; exit 1; }

action="$1"
domain="$2"
domain_conf_dir="${conf_dir}/${domain}"
[ -d "$domain_conf_dir" ] || mkdir -p "$domain_conf_dir"

if [ -n "${3:-}" ]; then
  auto_name=false
  name="$3"
else
  auto_name=true
  name="$(date +'%Y.%m.%d_%H.%M.%S')"
fi


case "$action" in
  create|c)
    _create
    ;;

  list|ls|l)
    _list
    ;;

  disks)
    _get_disks_path
    ;;

  delete|del|rm)
    _delete
    ;;

  revert|rev|r)
    _revert
    ;;

  soft-revert|srev|sr)
    _soft_revert
    ;;

  unrevert|unrev|ur)
    _unrevert
    ;;

  help|h)
    _help
    ;;

  *)
    _help
    exit 1
    ;;
esac
