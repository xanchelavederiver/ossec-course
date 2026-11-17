#!/usr/bin/env bash
# Run throwaway overlays of the reference lab VM (see create-base.sh).
#   vm.sh start [name]   create overlay .vm/images/<name>.qcow2 if missing and boot it
#   vm.sh ssh   [name] [cmd...]   run a command (or a shell) as the admin user
#   vm.sh stop  [name]   power the VM off (overlay is kept)
#   vm.sh reset [name]   stop and delete the overlay – next start is a clean server
# Default name: lab. SSH is forwarded to 127.0.0.1:${OSSEC_VM_PORT:-2226}.
set -Eeuo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
vm=$(cd "$here/../../.." && pwd)/.vm
cmd=${1:-}; name=${2:-lab}; port=${OSSEC_VM_PORT:-2226}
disk=$vm/images/$name.qcow2; pid=$vm/images/$name.pid
ssh_opts=(-i "$vm/ssh/id_ed25519" -p "$port" -o StrictHostKeyChecking=no
          -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5)
running() { [[ -f $pid ]] && kill -0 "$(<"$pid")" 2>/dev/null; }
case $cmd in
  start)
    running && { echo "$name is already running"; exit 0; }
    [[ -f $disk ]] || qemu-img create -q -f qcow2 -F qcow2 -b "$vm/images/base.qcow2" "$disk"
    qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 2048 \
      -drive file="$disk",if=virtio,format=qcow2 \
      -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:$port-:22" \
      -display none -daemonize -pidfile "$pid"
    for _ in $(seq 1 90); do
      ssh "${ssh_opts[@]}" ubuntu@127.0.0.1 true 2>/dev/null && { echo "$name is up (port $port)"; exit 0; }
      sleep 2
    done
    echo "$name did not answer on SSH" >&2; exit 1 ;;
  ssh)  shift; [[ $# -gt 0 ]] && shift; exec ssh "${ssh_opts[@]}" ubuntu@127.0.0.1 "$@" ;;
  stop)
    running || { echo "$name is not running"; exit 0; }
    ssh "${ssh_opts[@]}" ubuntu@127.0.0.1 sudo poweroff 2>/dev/null || true
    for _ in $(seq 1 30); do running || break; sleep 1; done
    running && kill "$(<"$pid")"; rm -f "$pid" ;;
  reset) "$0" stop "$name"; rm -f "$disk" ;;
  *) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
