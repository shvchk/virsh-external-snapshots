#! /usr/bin/env bash
set -euo pipefail

conf_dir="${HOME}/.local/VM/snapshots"
prefix="_pre_"


_help() {
  script_name="$(basename -- "$0")"

  printf "%s\n" \
  "${script_name}: easy to use external snapshots with virsh (disk-only)" \
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
  "disk                Show active disk" \
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
  "" \
  "Snapshots are created without metadata, so they won't be shown with \`virsh snapshot-list\`"
}

_die() {
  echo "${1}. Exit."
  exit 1
}

_has_disks() {
  virsh domblklist "$domain" --details | grep -qE 'file\s+disk' || return 1
}

_create() {
  _has_disks || _die "'${domain}' has no disks, nothing to snapshot"
  virsh dumpxml "$domain" > "${domain_conf_dir}/${prefix}${name}.xml"
  virsh snapshot-create-as "$domain" "$name" --disk-only --no-metadata --atomic
  virsh dumpxml "$domain" > "${domain_conf_dir}/${name}.xml"
}

_list() {
  for f in "${domain_conf_dir}"/*.xml; do
    f="$(basename -- "$f")"
    [ "${f:0:5}" != "_pre_" ] || continue
    echo "${f%.xml}";
  done
}

_disk() {
  virsh domblklist "$domain" --details | grep -E -m 1 'file\s+disk'
}

_delete() {
  disk="$(_disk | sed -E 's|[^/]+(.+)|\1|')"
  disk_dir="$(dirname "$disk")"
  sudo_cmd=""

  if [ ! -w "$disk_dir" ] || [ ! -x "$disk_dir" ]; then
    sudo_cmd="sudo"
    echo "Root privileges required to remove disk file"
  fi

  # We could just rm $disk, but after revert it won't point to the right snapshot disk path,
  # so we construct the right path manually
  [ -f "${disk_dir}/${domain}.${name}" ] && $sudo_cmd rm "${disk_dir}/${domain}.${name}"
  [ -f "${domain_conf_dir}/${name}.xml" ] && rm "${domain_conf_dir}/${name}.xml"
}

_soft_revert() {
  virsh define "${domain_conf_dir}/${prefix}${name}.xml"
}

_revert() {
  _soft_revert
  _delete
}

_unrevert() {
  virsh define "${domain_conf_dir}/${name}.xml"
}


[ -n "${1:-}" ] || _die 'No action specified'
[ -n "${2:-}" ] || { _help; exit 1; }

action="$1"
domain="$2"
name="${3:-$(date +'%Y.%m.%d_%H.%M.%S')}"
domain_conf_dir="${conf_dir}/${domain}"

[ -d "$domain_conf_dir" ] || mkdir -p "$domain_conf_dir"

case "$action" in
  create|c)
    _create
    ;;

  list|ls|l)
    _list
    ;;

  disk)
    _disk
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
