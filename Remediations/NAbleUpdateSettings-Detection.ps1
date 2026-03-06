<#
Script Name: NAbleUpdateSettings-Detection.ps1
Version: 2
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether old update settings deployed by 
N-Able are still present on the device.
If old settings are found, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

#>

#------------------------------------ Set Variables -------------------------------------#

$KeystoCheck = @(
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    },
    @{
    Key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache"
    }
)

#---------------------------- Check Windows Update Settings -----------------------------#

ForEach ($RegKey in $KeystoCheck){
    $keycheck = $RegKey.Key
if (Test-Path $keycheck)
    {
        Write-Host "Registry key $keycheck still exists, continuing to Remediation."
        Exit 1
    }
else {
Write-Host "$keycheck does not exist."
}
}
Write-Host "All registry keys have already been removed, exiting without further action."
Exit 0

