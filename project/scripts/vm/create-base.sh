#!/usr/bin/env bash
# Build the reference lab VM base image by an unattended install from the
# Ubuntu Server ISO. Result: .vm/images/base.qcow2 (never booted directly –
# vm.sh runs throwaway overlays on top of it).
# Needs: qemu-system-x86_64, qemu-img, cloud-localds, isoinfo, access to /dev/kvm.
set -Eeuo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../../.." && pwd)
vm=$root/.vm
iso=${OSSEC_VM_ISO:-$vm/iso/ubuntu-26.04.1-live-server-amd64.iso}
base=$vm/images/base.qcow2
build=$vm/build
lab_password=${OSSEC_VM_PASSWORD:-Lab-Demo-42!}   # public lab value

[[ -f $iso ]] || { echo "ISO not found: $iso" >&2; exit 1; }
[[ ! -e $base ]] || { echo "$base already exists; remove it to rebuild" >&2; exit 1; }
mkdir -p "$vm/images" "$vm/ssh" "$build"

[[ -f $vm/ssh/id_ed25519 ]] || ssh-keygen -q -t ed25519 -N '' -C ossec-lab -f "$vm/ssh/id_ed25519"
hash=$(openssl passwd -6 "$lab_password")
pub=$(<"$vm/ssh/id_ed25519.pub")
sed -e "s|@PASSWORD_HASH@|$hash|" -e "s|@SSH_PUBKEY@|$pub|" \
  "$here/autoinstall.yaml.in" >"$build/user-data"
printf 'instance-id: ossec-lab-install\n' >"$build/meta-data"
cloud-localds "$build/seed.iso" "$build/user-data" "$build/meta-data"

# Boot the installer kernel directly so that "autoinstall" can be put on its
# command line (otherwise the installer asks for confirmation).
isoinfo -i "$iso" -R -x /casper/vmlinuz >"$build/vmlinuz"
isoinfo -i "$iso" -R -x /casper/initrd >"$build/initrd"

qemu-img create -q -f qcow2 "$base.partial" 20G
echo "Installing; serial log: $build/install.log"
qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 4096 \
  -drive file="$base.partial",if=virtio,format=qcow2 \
  -drive file="$iso",media=cdrom,readonly=on \
  -drive file="$build/seed.iso",if=virtio,format=raw,readonly=on \
  -kernel "$build/vmlinuz" -initrd "$build/initrd" \
  -append 'autoinstall console=ttyS0,115200' \
  -nic user,model=virtio-net-pci \
  -display none -serial "file:$build/install.log" -no-reboot
mv "$base.partial" "$base"
chmod a-w "$base"
echo "Done: $base"
