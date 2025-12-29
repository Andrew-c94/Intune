<#
Script Name: NableUpdateSettings-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to remove Windows Update settings that are no
longer required.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$ErrorActionPreference = "Stop"

#---------------------------- Remove Windpws Update Settings -------------------------------#

Try{
    if (Test-Path $Key)
    {
    Write-Host "Registry key $Key still exists, removing."
    }
    else {
    Write-Host "Registry key $key has already been removed, exiting without further action."
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Host "An error has occured. ERROR:'$errMsg'. Exiting Script."
    Exit 1
    }

Write-Host "Settings cleaned up successfully."
Exit 0