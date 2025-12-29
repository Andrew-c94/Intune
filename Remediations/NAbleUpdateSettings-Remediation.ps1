<#
Script Name: NableUpdateSettings-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to remove Windows Update settings that are no
longer required.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$KeytoCheck = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$KeytoDelete = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$ErrorActionPreference = "Stop"

#---------------------------- Remove Windpws Update Settings -------------------------------#

Try{
    if (Test-Path $KeytoCheck)
    {
    Write-Host "Registry key $KeytoCheck still exists, removing."
    Remove-Item $KeytoDelete -Force -Recurse
    }
    else {
    Write-Host "Registry key $KeytoCheck has already been removed, exiting without further action."
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Host "An error has occured. ERROR:'$errMsg'. Exiting Script."
    Exit 1
    }

Write-Host "Settings cleaned up successfully."
Exit 0