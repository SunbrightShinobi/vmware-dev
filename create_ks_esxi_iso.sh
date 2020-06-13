#!/bin/bash

echo "Creating Custom VMware-$1 ISO with bootable vSphere ESXi and kickstarts, vCenter and VM deployment scripts"
curPath=$(pwd)
esxiRelease="7.0.0-15843807"
rm -rf /tmp/esxi_custom
mkdir /tmp/esxi_custom

echo "Extracting Custom VMware vSphere ESXi Installer files"
unzip -q ./customESXi_iso/*.zip -d /tmp/esxi_custom

echo "Copying Custom $1 ESXi Kickstart files"
cp -rf ./kickstarts/$1/* /tmp/esxi_custom

if [ $1 == HOMELAB ]
then
    isoName="BINARY_HOMELAB-M001"
    cp -rf ./kickstarts/HOMELAB/KS/* /tmp/esxi_custom/KS
    echo "Copying Powershell VMware PowerCLI zip for $isoName"
    cp ./Powershell5_VMware_PowerCLI.zip /tmp/esxi_custom
elif [ $1 == SKU ]
then
    isoName="SKU-VMWARE-M001"
    grep -rli '/tmp/esxi_custom/KS' -e '$1$GZPBNahQ$LvPBFpVijYnKeJa8tFH/M/' | xargs sed -i 's~$1$GZPBNahQ$LvPBFpVijYnKeJa8tFH/M/~$1$a0agQumj$wvDocxN3rKg5D7bId2BYh.~g'
    echo "Copying COE Custom ESXi vCenter files for $isoName"
    mkdir /tmp/esxi_custom/vcenter
    unzip -q ./vcenter/*.zip -d /tmp/esxi_custom/vcenter/source
    cp -rf ./vcenter/*.json /tmp/esxi_custom/vcenter
    cp -rf ./vcenter/dod_banner.txt /tmp/esxi_custom/vcenter
    cp -rf ./vcenter/vcenter_config.ps1 /tmp/esxi_custom/vcenter
    cp -rf ./vcenter/vcenter_vapp_deploy.ps1 /tmp/esxi_custom/vcenter
fi

grep -rli '/tmp/esxi_custom/EFI/BOOT/refind.conf' -e '<dev-release>' | xargs sed -i 's~<dev-release>~'$(git describe)'~g'
grep -rli '/tmp/esxi_custom/ISOLINUX.CFG' -e '<dev-release>' | xargs sed -i 's~<dev-release>~'$(git describe)'~g'

grep -rli '/tmp/esxi_custom/EFI/BOOT/refind.conf' -e '<esxi-release>' | xargs sed -i 's~<esxi-release>~'$esxiRelease'~g'
grep -rli '/tmp/esxi_custom/ISOLINUX.CFG' -e '<esxi-release>' | xargs sed -i 's~<esxi-release>~'$esxiRelease'~g'

echo "Copying Custom ESXi VM Deployment Scripts and Configs for $isoName"
mkdir /tmp/esxi_custom/deploy_vms
cp -rf ./deploy_vms/*.ps1 /tmp/esxi_custom/deploy_vms
cp -rf ./deploy_vms/ovas /tmp/esxi_custom/deploy_vms

if [ $1 == HOMELAB ]
then
    cp -rf ./deploy_vms/SKU/tmp/esxi_custom/deploy_vms
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/esxi65_template
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/pfsense_vmob
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/ubuntu_template
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/windows10_template
elif [ $1 == SKU ]
then
    cp -rf ./deploy_vms/SKU/tmp/esxi_custom/deploy_vms
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/esxi65_template
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/pfsense_vmob
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/ubuntu_template
    rm -rf /tmp/esxi_custom/deploy_vms/ovas/windows10_template
fi

echo "Copying Required ESXi Post-Installation files for $isoName"
cp -rf ./post_files /tmp/esxi_custom/

echo "Copying Required ESXi Upgrade files for $isoName"
cp -rf ./customESXI_iso/esxi_izip/*.zip /tmp/esxi_custom/vsphere_upgrade
cp -rf ./vcenter/upgrade/*.iso /tmp/esxi_custom/vsphere_upgrade

echo "Building $isoname Bootable ISO"
cd /tmp/esxi_custom
chmod 777 ISOLINUX.BIN
mkisofs -relaxed-filenames -J -r\
 -b ISOLINUX.BIN -iso-level 2\
 -c BOOT.CAT -no-emul-boot -boot-load-size 4 -boot-info-table\
 -eltorito-alt-boot -eltorito-boot EFIBOOT.IMG -no-emul-boot\
 -V $isoName\
 -o /mnt/c/TEMP/$isoName.iso\
 .

echo "Bootable $isoname ISO build complete"
cd $curPath
