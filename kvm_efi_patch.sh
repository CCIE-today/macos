#!/bin/bash

source /etc/rht

function modify_xml_efi {
    # xml modify
    sed -i.bk \
    -e "/<\/os/i\                <loader readonly='yes' secure='yes' type='pflash'>/usr/share/OVMF/OVMF_CODE.secboot.fd</loader>" \
    -e "/<\/os/i\                <nvram>/var/lib/libvirt/qemu/nvram/${VM}_VARS.fd</nvram>" \
    -e "/<\/features/i\                <smm state='on'/>" $XML_FILE
}
function modify_xml {
    # xml modify efi+vdb
    sed -i.bk \
    -e "/<\/os/i\                <loader readonly='yes' secure='yes' type='pflash'>/usr/share/OVMF/OVMF_CODE.secboot.fd</loader>" \
    -e "/<\/os/i\                <nvram>/var/lib/libvirt/qemu/nvram/${VM}_VARS.fd</nvram>" \
    -e "/<\/features/i\                <smm state='on'/>" \
    -e "/<\/devices/i\                <disk device='disk' type='file'>" \
    -e "/<\/devices/i\                        <target bus='virtio' dev='vdx'/>" \
    -e "/<\/devices/i\                        <source file='$IMAGE_EFI'/>" \
    -e "/<\/devices/i\                        <driver name='qemu' type='qcow2'/>" \
    -e "/<\/devices/i\                </disk>" $XML_FILE
}
function modify_grub {
    # /boot/grub2
    mkdir /tmp/$VM
    # grubenv
    guestfish -a $IMAGE_FILE -i copy-out /boot/grub2/grubenv /tmp/$VM/
    # grub.cfg
    cp /boot/efi/EFI/redhat/grub.cfg /tmp/$VM/
    ROOT_UUID=$(awk '/set=root/{print $NF}' /tmp/$VM/grub.cfg | uniq)
    BOOT_UUID=$(awk '/set=boot/{print $NF}' /tmp/$VM/grub.cfg | uniq)
    NEW_UUID=$(awk '/kernelopts/{print $1}' /tmp/$VM/grubenv | awk -F = '{print $NF}')
    sed -i -e "s/$ROOT_UUID/$NEW_UUID/" -e "s/$BOOT_UUID/$NEW_UUID/" /tmp/$VM/grub.cfg
}
function modify_efi {
    # EFI
    qemu-img create -f qcow2 $IMAGE_EFI 128M >/dev/null
    guestfish -a $IMAGE_EFI run : \
        part-disk /dev/sda gpt : \
        mkfs vfat /dev/sda1 : \
        mount /dev/sda1 / : \
        copy-in /boot/efi/EFI / : \
        rm-f /EFI/redhat/grubenv : \
        rm-f /EFI/redhat/grub.cfg : \
        rm-f /EFI/redhat/user.cfg : \
        copy-in /tmp/$VM/grubenv /EFI/redhat/ : \
        copy-in /tmp/$VM/grub.cfg /EFI/redhat/
}

# Main Area
for i in $RHT_VM0 $RHT_VMS; do
    VM=$i
    case $VM in
    classroom)
        IMAGE_FILE=/var/lib/libvirt/images/$RHT_COURSE-$VM-vda.qcow2
        IMAGE_EFI=/var/lib/libvirt/images/$RHT_COURSE-$VM-vdx.qcow2
        XML_FILE=/var/lib/libvirt/images/$RHT_COURSE-$VM.xml
        ;;
    *)
        IMAGE_FILE=/content/$RHT_VMTREE/vms/$RHT_COURSE-$VM-vda.qcow2
        IMAGE_EFI=/var/lib/libvirt/images/$RHT_COURSE-$VM-vdx.qcow2
        XML_FILE=/content/$RHT_VMTREE/vms/$RHT_COURSE-$VM.xml
        ;;
    esac
    case $RHT_VMTREE in
    rhel8.0/x86_64)
        modify_xml
        VMM=$(ls -l /content/$RHT_VMTREE/vms/$RHT_COURSE-*-vda.qcow2 | awk '$2!=1{print $NF}' | awk -F - 'NR==1{print $2}')
        if echo $(ls -l /content/$RHT_VMTREE/vms/$RHT_COURSE-*-vda.qcow2 | awk '$2!=1{print $NF}') | grep -q $VM; then
            if [ "$VMM" == "$VM" ]; then
                modify_grub
                modify_efi
            else
                cp /var/lib/libvirt/images/$RHT_COURSE-$VMM-vdx.qcow2 $IMAGE_EFI
            fi
        else
            modify_grub
            modify_efi
        fi ;;
    *)
        modify_xml_efi ;;
    esac
done