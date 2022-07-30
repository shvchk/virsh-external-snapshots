## virsh-snap.sh: easy to use external snapshots

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

- Create snapshot named `snapshot-1` of `vm-42`:
  ```sh
  virsh-snap.sh create vm-42 snapshot-1
  ```
  Snapshot name is optional, by default current date and time is used as a name, e.g. `2022.07.29_23.55.12`.

- List snapshots of `vm-42`:
  ```sh
  virsh-snap.sh list vm-42
  ```
  Note that this is not the same as `virsh snapshot-list`. Snapshots are created without metadata and won't be shown with `virsh snapshot-list`.

- Revert and delete `snapshot-1` of `vm-42`:
  ```sh
  virsh-snap.sh revert vm-42 snapshot-1
  ```

- Revert, but don't delete `snapshot-1` of `vm-42`:
  ```sh
  virsh-snap.sh soft-revert vm-42 snapshot-1
  ```
  This allows to use this snapshot later with `unrevert`.

- Undo revert of a `snapshot-1` of `vm-42`, i.e. make it active again:
  ```sh
  virsh-snap.sh unrevert vm-42 snapshot-1
  ```

- Delete snapshot `snapshot-1` of `vm-42`:
  ```sh
  virsh-snap.sh delete vm-42 snapshot-1
  ```
  Might be useful if you change your mind after `soft-revert`.

- Show help:
  ```sh
  virsh-snap.sh help
  ```
  ```
  virsh-snap.sh: easy to use external snapshots

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

  help, h             This message


  Snapshots are created without metadata, so they won't be shown with `virsh snapshot-list`
  ```
