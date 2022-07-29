## virsh-snap.sh: easy to use external snapshots (disk-only)

### Installation

- Download script:
  ```sh
  wget -P ~/.local/bin https://github.com/shvchk/virsh-external-snapshots/raw/main/virsh-snap.sh
  ```
- Make it executable:
  ```sh
  chmod +x ~/.local/bin/virsh-snap.sh
  ```


### Usage

```
Usage: virsh-snap.sh <action> <domain> [snapshot name]


Actions:
--------
create, c           Create snapshot
                    If no snapshot name is provided, current date and time is used

list, ls, l         List snapshots

disk                Show active disk

revert, rev, r      Revert snapshot and delete it (same as soft-revert + delete)

soft-revert,
srev, sr            Revert snapshot without deleting it (allows unrevert)

unrevert,
unrev, ur           Unrevert snapshot, i.e. make soft-reverted snapshot active again

delete, del, rm     Delete snapshot


Snapshots are created without metadata, so they won't be shown with `virsh snapshot-list`
```
