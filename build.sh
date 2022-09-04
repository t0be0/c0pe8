#!/bin/bash

KERNEL_VERSION=5.15.64
BUSYBOX_VERSION=1.35.0

### Uncomment below line to install Linux C0mpiling essentials
# sudo apt-get install fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison -y

_die()
{
    echo "[!] $*"
    exit
}

mkdir -p source
cd source
    
    echo "[+] Checking Source Files"
    
    #KERNEL
    if [ ! -d linux-$KERNEL_VERSION ];
    then
    
        wget \
        "https://cdn.kernel.org/pub/linux/kernel/v`echo $KERNEL_VERSION | cut -d'.' -f1`.x/linux-$KERNEL_VERSION.tar.gz" \
        -O linux-$KERNEL_VERSION.tar.gz
        
        gunzip linux-$KERNEL_VERSION.tar.gz
        tar -xf linux-$KERNEL_VERSION.tar
        rm -f linux-$KERNEL_VERSION.tar
        
    fi

    #BUSYBOX
    if [ ! -d busybox-$BUSYBOX_VERSION ];
    then
    
        wget \
        "https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2" \
        -O busybox-$BUSYBOX_VERSION.tar.bz2

        bunzip2 busybox-$BUSYBOX_VERSION.tar.bz2
        tar -xf busybox-$BUSYBOX_VERSION.tar
        rm -f busybox-$BUSYBOX_VERSION.tar
    
    fi
    
    echo "[+] Setting up"
    
    #KERNEL
    cd linux-$KERNEL_VERSION
    if [ ! -f arch/x86/boot/bzImage ];
    then
    
        make defconfig || _die "defconfig failed for kernel ('make defconfig' inside `pwd`), Exitting..."
        make -j`nproc` || _die "Error while compiling kernel ('make -j`nproc`' inside `pwd`), Exitting..."
    fi
    cd ../
    
    #BUSYBOX
    cd busybox-$BUSYBOX_VERSION
    if [ ! -f busybox ];
    then
        
        make defconfig || _die "defconfig failed for busybox ('make defconfig' inside `pwd`), Exitting..."
        sed "s/^.*CONFIG_STATIC[^_]*$/CONFIG_STATIC=y/g" -i .config
        make -j`nproc` || _die "Error while compiling Busybox ('make -j`nproc`' inside `pwd`), Exitting..."
    fi
    cd ../
    
cd ../

rm -rf initrd
mkdir -p initrd
cd initrd

    mkdir -p bin dev proc sbin sys
    cd bin
        cp ../../source/busybox-$BUSYBOX_VERSION/busybox .
        for binary in `./busybox --list`
        do
            ln -s busybox ./$binary
        done
    cd ../
    cd sbin/
    
        echo "#!/bin/sh" > init.sh
        echo "mount -t proc proc /proc" >> init.sh
        echo "mount -t sysfs sys /sys" >> init.sh
        echo "mount -t devtmpfs dev /dev" >> init.sh
        echo "mkdir -p /dev/pts" >> init.sh
        echo "mount -t devpts dev/pts /dev/pts" >> init.sh
        
        echo "clear" >> init.sh
        
        echo "echo '======c0pe8 Linux======'" >> init.sh
        echo "echo '@deathpicnic'" >> init.sh
        echo ""
        
        #echo "/bin/sh" >> init.sh
        # some hackish workaround for [sh: can't access tty; job control turned off]
        echo "setsid cttyhack sh" >> init.sh
        
        echo "cd /" >> init.sh
        echo "umount ./dev/pts" >> init.sh
        echo "umount ./dev" >> init.sh
        echo "umount ./sys" >> init.sh
        echo "umount ./proc" >> init.sh
        echo "poweroff -f" >> init.sh

        chmod +x init.sh
    cd ../

    ln -s sbin/init.sh init

    find . | cpio -o -H newc > ../initrd.img

cd ../

mkdir -p build
cd build
    cp ../source/linux-$KERNEL_VERSION/arch/x86/boot/bzImage .
    mv ../initrd.img .
cd ../
rm -rf initrd*

echo "[+] Built Success"
echo "[^] try running with qemu (x86_64) using './run.sh'"
