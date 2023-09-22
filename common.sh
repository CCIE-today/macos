#!/bin/bash

function sudo_NOPASS {
    UN=alex
    GN=$(sudo grep ^% /etc/sudoers | awk '{print $1}' | sed 's/%//')
    sudo dscl localhost -append /Local/Default/Groups groupname %GN $UN
    sudo sed -i.bk '/admin/s?ALL$?NOPASSWD: ALL?' /etc/sudoers
}

function spctl_disable {
    # 允许从以下位置下的App: 任何来源
    if spctl --status | grep -wq enabled; then
        sudo spctl --master-disable
    fi
    echo
    spctl --status
}

function disable_adobe_update {
    # 禁用 adobe 更新
    sudo rm -rf /Applications/Adobe\ Acrobat\ DC/Adobe\ Acrobat.app/Contents/Plugins/Updater.acroplugin
}

function vmnet1_host {
    VFN="/Library/Preferences/VMware Fusion/networking"
    if [ -f $VFN ]; then
        sudo sed -i.bk \
        -e '/VNET_1_DHCP /s/yes/no/' \
        -e '/VNET_1.*NETMASK/s/NETMASK.*/NETMASK 255.255.255.0/' \
        -e '/VNET_1.*SUBNET/s/SUBNET.*/SUBNET 172.25.254.0/' "${VFN}"
    fi
}

function rht_usb_locale {
    # Failed to set locale, defaulting to C
    PF=/etc/profile
    if ! grep -wq 'export LC_ALL=en_US.UTF-8' $PF; then
        echo "export LC_ALL=en_US.UTF-8" | sudo tee -a $PF
        source $PF
    fi
}

function iterm2_LC {
    # man: can't set the locale; make sure $LC_* and $LANG are correct
    if uname -s | grep -wq Darwin; then
        sudo sed -i.bk /LC/s/^/#/ /etc/ssh/ssh_config
    fi
}

function install_homebrew {
    # 安装 CLT for Xcode
    xcode-select --install
    # 设置环境变量
    /bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
}

function install_libvirt {
    brew install qemu gcc libvirt
    brew services start libvirt
    brew services enable libvirt
}

function set_hostname {
    sudo scutil --set HostName iMac
}

function disable_Office_AutoUpdate {
    sudo chmod a-rwx /Library/Application\ Support/Microsoft/MAU2.0/Microsoft\ AutoUpdate.app
}

# Main Area
sudo_NOPASS
spctl_disable
vmnet1_host
iterm2_LC

install_homebrew
install_libvirt

disable_Office_AutoUpdate
disable_adobe_update