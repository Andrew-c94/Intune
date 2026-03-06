<#
Script Name: NableUpdateSettings-Remediation.ps1
Version: 2
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to remove Windows Update settings that are no
longer required.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$KeystoCheckandDelete = @(
    @{
    Keytocheck = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    Keytodelete = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    },
    @{
    Keytocheck = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache"
    Keytodelete = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache"
    }
)

$ErrorActionPreference = "Stop"

#---------------------------- Remove Windpws Update Settings -------------------------------#

ForEach ($RegKey in $KeystoCheckandDelete){
    $Keycheck = $RegKey.Keytocheck
    $Keydelete = $RegKey.Keytodelete
    Try{
        if (Test-Path $Keycheck)
        {
        Write-Host "Registry key $Keycheck still exists, removing."
        Remove-Item $Keydelete -Force -Recurse
        }
        else {
        Write-Host "Registry key $Keycheck has already been removed."
        }
    }
catch {
    $errMsg = $_.Exception.Message
    Write-Host "An error has occured. ERROR:'$errMsg'. Exiting Script."
    Exit 1
    }
}

Write-Host "All reg keys cleaned up successfully."
Exit 0