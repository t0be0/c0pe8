qemu-system-x86_64 -nographic -no-reboot -kernel build/bzImage -initrd build/initrd.img -append "panic=1 console=ttyS0 HOST=x86_64"
