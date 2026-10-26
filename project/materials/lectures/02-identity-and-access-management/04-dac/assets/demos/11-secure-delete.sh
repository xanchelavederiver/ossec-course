#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='chattr +s on ext2: claimed secure deletion is not implemented'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need losetup mkfs.ext2 debugfs dumpe2fs xxd
IMG=/tmp/ossec-ext2.img
LOOP=
cleanup() {
  mountpoint -q /mnt && umount /mnt
  [[ -z $LOOP ]] || losetup -d "$LOOP" 2>/dev/null
  rm -f "$IMG"
}

echo; echo '===== Стенд: ext2 на loop-устройстве ====='
run dd if=/dev/zero of="$IMG" bs=1M count=64
LOOP=$(losetup --show -f "$IMG"); echo "LOOP=$LOOP"
run mkfs.ext2 "$LOOP"
run file -sL "$LOOP"
run mount "$LOOP" /mnt
run bash -c 'echo "Hello, secure deletion via attr s!" > /mnt/file.txt'
run sync

echo; echo '===== Расположение данных на устройстве ====='
run bash -c "debugfs -R 'stat file.txt' $LOOP 2>/dev/null | grep -A 1 'BLOCKS:'"
OFFSET=$(debugfs -R "stat file.txt" "$LOOP" 2>/dev/null | grep -A 1 "BLOCKS:" | tail -n 1 | cut -d ":" -f 2)
BS=$(dumpe2fs "$LOOP" 2>/dev/null | grep "Block size" | awk '{print $3}')
echo "Block offset: $OFFSET  Block size: $BS"
run bash -c "dd if=$LOOP bs=$BS skip=$OFFSET count=1 status=none | xxd -l 48"

echo; echo '===== chattr +s, удаление, повторное чтение ====='
run chattr +s /mnt/file.txt
run lsattr /mnt/file.txt
run rm -f /mnt/file.txt
run sync
run bash -c "dd if=$LOOP bs=$BS skip=$OFFSET count=1 status=none | xxd -l 48"
echo
echo 'Данные НЕ перезаписаны: атрибут s не реализован (см. слайды раздела 5.3).'
