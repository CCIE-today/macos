#!/bin/zsh

echo System Version: macOS 12

if system_profiler SPSoftwareDataType | grep -q 'System.*Version.*macOS.*11'; then
    brew tap jeffreywildman/homebrew-virt-manager
    brew install virt-manager virt-viewer
fi

if system_profiler SPSoftwareDataType | grep -q 'System.*Version.*macOS.*12'; then
    brew tap rombarcz/homebrew-virt-manager
    brew install virt-manager virt-viewer

    brew install qemu libvirt
    echo 'security_driver = "none"' >> /usr/local/etc/libvirt/qemu.conf
    echo 'dynamic_ownership = 0' >> /usr/local/etc/libvirt/qemu.conf
    echo 'remember_owner = 0' >> /usr/local/etc/libvirt/qemu.conf

    sed -i.bk -e '/unix_sock_group/s_#__' -e '/unix_sock_group/s_libvirt_admin_' -e '/unix_sock_rw/s_#__' -e '/auth_unix_rw.*=/s_#__' /usr/local/etc/libvirt/libvirtd.conf
    brew services start libvirt
fi