<#
Creator: Josh Johnson - josh.johnson@ngc.com
Description:
    This script install NuGet and VMware PowerCLI to the user running
    PowerShell. Then runs the ESXi Customizer script to build the latest
    patched ESXi v6.5 iso file in built_iso folder including the vmware
    maclearn plugin for being able to run nested hypervisors, as well as any
    pkgs in vibs directory.

Breakdown of Commands/Attributes:
    -nsc = Use -NoSignatureCheck with export
    -sip = Prompts you to select an Imageprofile from the current list. Without
        this it will autoselect the latest profile.
    -v65 = Use only ESXi 6.5 Imageprofiles as input
        vmware-esx-dvfilter-maclearn = A vib for allowing a ESXi virtual switch
            to learn MAC addresses to allow to nested ESXi installations. For
            example development of ESXi installer scripts install multiple
            virtual "nested" ESXi servers inside another ESXI server.
    -outDir = Selects folder for log file and created ISO file

Ensure any vibs in folder for installation are PartnerSelected or host
will fail security scans.
#>
param(
[parameter(Mandatory=$False)][string]$path = "C:\TEMP", # Location of share for all files
[parameter(Mandatory=$False)][string]$izipSourcePath = ".\esxi_izip\", # Location in share where VMware update packages are kept
[parameter(Mandatory=$False)][string]$pkgSourcePath = ".\esxi_vibs\", # Location in share where Supplier vibs/drivers are kept
[parameter(Mandatory=$True)][string]$source_izip = "ESXi-7.0.0-15843807-standard.zip", # Offline individual update package from VMware to build ISO from
[parameter(Mandatory=$True)][string]$esxiVersion ="7.0.0", # VMware vSphere ESXi Version Number ex. "x.x.x"
[parameter(Mandatory=$True)][string]$esxiBuild = "-15843807", # VMware vSphere ESXi Build Number
[parameter(Mandatory=$False)][string]$description = "VMware vSphere ESXi Installer, for "+$esxiVersion+$esxiBuild, # Description of ISO in install menu
[parameter(Mandatory=$False)][string]$vendor = "Binarylandscapes Consulting", # Vendor of custom ISO
[parameter(Mandatory=$False)][string]$isoName = "ESXi-"+$esxiVersion+$esxiBuild+"-standard" # Name for ISO when created
)

Write-Host "Offline Custom VMware vSphere ESXi Installer iZIP Generator"

$izip = $izipSourcePath+$source_izip

# Create the custom bootable ISO
.\ESXi-Customizer-PS-v2.6.2.ps1 `
-izip $izip `
-nsc `
-ipname $isoName `
-ipdesc $description `
-ipvendor $vendor `
-outDir $path
#-pkgDir "$pkgSourcePath\community",`
#        "$pkgSourcePath\hpe_dl380g10_oem" `

$isoPath = $path+"\"+$isoName+".iso"
# Mount ISO
$mountedISO = Mount-DiskImage -ImagePath $isoPath -PassThru
$isoDrive = $(Get-Volume -DiskImage $mountedISO).DriveLetter + ":\"
$zipSource = $isoDrive + "*"
Compress-Archive -Path $zipSource -DestinationPath .\$isoName.zip -Force
Dismount-DiskImage $mountedISO.ImagePath
Remove-Item $isoPath -Force
