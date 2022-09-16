#!/bin/bash

# qemu-system-x86_64

while getopts "d:" arg; do
  case $arg in
    d) HDA=$OPTARG;;
  esac
done

if [ ! -z $HDA ]; then

    qemu-system-x86_64 -nographic -no-reboot \
    -kernel build/bzImage -initrd build/initrd.img \
    -append "panic=1 console=ttyS0 HOST=x86_64" \
    -hda $HDA -m 256M
else
    qemu-system-x86_64 -nographic -no-reboot \
    -kernel build/bzImage -initrd build/initrd.img \
    -append "panic=1 console=ttyS0 HOST=x86_64" \
    -m 256M

fi
