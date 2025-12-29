<#
Script Name: NAbleUpdateSettings-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether old update settings deployed by 
N-Able are still present on the device.
If old settings are found, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

#>

#------------------------------------ Set Variables -------------------------------------#

$Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

#---------------------------- Check Windows Update Settings -----------------------------#

if (Test-Path $Key)
    {
        Write-Host "Registry key $Key still exists, continuing to Remediation."
        Exit 1
    }
else {
Write-Host "Registry key $key has already been removed, exiting without further action."
Exit 0
    }

