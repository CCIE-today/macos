#!/bin/bash

cat > /dev/null <<EOF
- 参考
    kernel    | https://wiki.t2linux.org
    nomodeset | https://ubuntuqa.com/article/901.html
- 环境
    OS        | RHEL8.0
    MBP       | MacBook Pro(16-inch, 2019)
    kernel    | 5.16.2
- 已解决
    Wifi, DKMS, Audio, Fan, Kernel
- 待解决
    touchbar, Hybrid Graphics，麦克风，蓝牙，摄像头
EOF

# define vars
pkgver=5.16.2

# define function
function prepare_env {
    if [ ! -f /etc/yum.repos.d/centos-8-for-x86_64.repo ]; then
        wget -P /etc/yum.repos.d https://gitee.com/suzhen99/redhat/raw/master/centos-8-for-x86_64.repo
    fi
    for i in flex bison openssl-devel make gcc ncurses-devel elfutils-libelf-devel git dkms; do
        if ! rpm -q $i &>/dev/null; then
            yum -y install $i
        fi
    done
}

function kernel_build {
    # 0. make working director
    cd /usr/src
    
    # 1. download patches
    git clone --depth=1 https://gitee.com/suzhen99/mbp-16.1-linux-wifi.git patches || exit
    sed -i "/^pkgver/s/=.*/=${pkgver}/" patches/PKGBUILD
    source patches/PKGBUILD
    
    # 2. download kernel
    wget https://www.kernel.org/pub/linux/kernel/v${pkgver//.*}.x/linux-${pkgver}.tar.xz
    tar xf linux-${pkgver}.tar.xz
    cd linux-${pkgver}
    
    # 3. add drivers
    git clone --depth=1 https://gitee.com/suzhen99/apple-bce-drv.git drivers/staging/apple-bce || exit
    git clone --depth=1 https://gitee.com/suzhen99/apple-ib-drv.git drivers/staging/apple-ibridge || exit
    
    # 4. add patches
    for patch in ../patches/*.patch; do
        patch -Np1 < $patch
    done
    
    # 5. Setting kernel configuration
    \cp /boot/config* .config
    cat >> .config <<EOF
CONFIG_SPI_PXA2XX=m
CONFIG_SPI_PXA2XX_PCI=m
EOF
    make olddefconfig
    scripts/config --module apple-ibridge
    scripts/config --module apple-bce
    
    # 6. Building
    ## CONFIG_SYSTEM_TRUSTED_KEYRING=
    sed -i '/CONFIG_SYSTEM_TRUSTED_KEYS/s_^_#_' .config
    echo -e "\n" | make -j$(nproc)
    
    # 7. Installing
    export MAKEFLAGS=-j$(nproc)
    make modules_install
    make install
}

function update_grub {
    # nomodeset.    | 新内核不添加无法启动
    # net.ifnames=0 | eth0
    if ! grep -wq nomodeset /etc/default/grub; then  
        sed -i '/GRUB_CMDLINE_LINUX/s_"$_ nomodeset net.ifnames=0"_' /etc/default/grub
    fi
    grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
    grubby --default-kernel
}

function selinux_update {
    restorecon -Rv /
}

function t2_ibridge {
    pkgver=5.16.2
    # bce
    git clone  https://gitee.com/suzhen99/apple-bce-drv.git /usr/src/apple-bce-0.2 || exit
    cat > /usr/src/apple-bce-0.2/dkms.conf <<EOF
PACKAGE_NAME="apple-bce"
PACKAGE_VERSION="$pkgver"
MAKE[0]="make KVERSION=$pkgver"
CLEAN="make clean"
BUILT_MODULE_NAME[0]="apple-bce"
DEST_MODULE_LOCATION[0]="/kernel/drivers/misc"
AUTOINSTALL="yes"
EOF
    dkms install -m apple-bce -v 0.2
    
    # ib
    git clone -b mbp15 https://gitee.com/suzhen99/apple-ib-drv /usr/src/apple-ibridge-0.1 || exit
    dkms install -m apple-ibridge -v 0.1
    
    # t2.modules
    cat > /etc/sysconfig/modules/t2.modules <<EOF
#!/bin/bash

# apple-bce
/sbin/modprobe apple-bce

# applespi
/sbin/modprobe industrialio_triggered_buffer
/sbin/modprobe apple-ibridge
/sbin/modprobe apple_ib_tb fnmode=2
/sbin/modprobe apple_ib_als

# brcmfmac
#/sbin/modprobe brcmfmac
EOF
    chmod +x /etc/sysconfig/modules/t2.modules
}

function t2_fan {
    git clone https://gitee.com/suzhen99/mbpfan.git || exit
    cd mbpfan/
    make install
    cp mbpfan.service /etc/systemd/system/
    systemctl enable mbpfan
    systemctl daemon-reload
    systemctl start mbpfan
}

function t2_wifi {
    # https://github.com/t2linux/wiki/blob/a4b46a7cfbe7efcbb6a0b6111e22172b0f5c4a77/docs/guides/wifi.md
    # # cat /sys/devices/virtual/dmi/id/product_name
    # Model             Identifier	Chipset	Revision	Island	Firmware Options
    # MacBookPro16,1	BCM4364	    4	                Bali	Big Sur
    # mac% ioreg -l | grep RequestedFiles
    #   "RequestedFiles" = ({
    #       "Firmware"="C-4364__s-B3/bali.trx",
    #       "TxCap"="C-4364__s-B3/bali-X2.txcb",
    #       "Regulatory"="C-4364__s-B3/bali-X2.clmb",
    #       "NVRAM"="C-4364__s-B3/P-bali-X2_M-HRPN_V-m__m-7.9.txt"
    #   })

    # 使用 ubuntu 固件可用
    git clone https://gitee.com/suzhen99/mbp-ubuntu.git || exit
    tar -xf mbp-ubuntu/files/brcm.tar.gz
    rm /lib/firmware/brcm/*
    cp brcm.ubuntu/*4364b3* /lib/firmware/brcm/
    modprobe -r brcmfmac && modprobe brcmfmac
    nmcli dev wifi list
    nmcli dev status
}

function t2_gpu {
    # 物理机启动时 <Command-R>
    # # csrutil disable
    # # reboot

    # install dep
    yum -y install gnu-efi-devel
    git clone https://gitee.com/suzhen99/apple_set_os-loader.git || exit
    cd apple_set_os-loader
    # modify Makefile
    sed -i -e '/^LDFLAGS/s|r/lib|r/lib64/gnuefi|' -e '/crt0/s|lib|lib64/gnuefi|' -e '/libgnuefi/s|/lib|/lib64|' Makefile
    make
    mv /boot/efi/EFI/redhat/grubx64.efi /boot/efi/EFI/BOOT/bootx64_original.efi
    cp ./bootx64.efi /boot/efi/EFI/redhat/grubx64.efi
    
    reboot

    curl https://gitee.com/suzhen99/redhat/raw/master/gpu-switch > /usr/local/bin/gpu-switch
    chmod +x /usr/local/bin/gpu-switch
    gpu-switch -i
    # ERROR：无法切换。貌似与内核参数 nomodeset 冲突
    # # journalctl -k --grep=efi:
    # Jan 27 19:58:25 foundation0.ilt.example.com kernel: efi: Apple Mac detected, using EFI v1.10 runtime services only
    # Jan 27 19:58:25 foundation0.ilt.example.com kernel: efi: ACPI=0x7affe000 ACPI 2.0=0x7affe014 SMBIOS=0x7aecf000 SMBIOS>
    # Jan 27 19:58:25 foundation0.ilt.example.com kernel: efi: Froze efi_rts_wq and disabled EFI Runtime Services
    # Jan 27 19:58:25 foundation0.ilt.example.com kernel: efi: EFI Runtime Services are disabled!
}

# Main area
if uname -r | grep -q 4.18; then
    prepare_env
    kernel_build
    update_grub
    selinux_update
    sync && reboot
elif uname -r | grep -q 5.16; then
    t2_ibridge
    t2_fan
    t2_wifi
    # t2_gpu
fi