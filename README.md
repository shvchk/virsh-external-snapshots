## External snapshots with virsh

### Installation

- Download script:
  ```sh
  wget -qP ~/.local/bin https://github.com/shvchk/virsh-external-snapshots/raw/main/virsh-snap.sh
  ```
- Make it executable:
  ```sh
  chmod +x ~/.local/bin/virsh-snap.sh
  ```


### Usage

```
Usage: virsh-snap.sh <action> <domain> [name]

Actions:
  create, c         Create snapshot

  list, ls, l       List all domain snapshots

  disk              Show active disk

  revert, rev, r    Revert snapshot and delete it (same as soft-revert + delete)

  soft-revert,
  srev, sr          Revert snapshot without deleting it (allows unrevert)

  unrevert,
  unrev, ur         Unrevert snapshot, i.e. make soft-reverted snapshot active again

  delete, del, rm   Delete snapshot
```
