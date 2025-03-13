<#
Script Name: DeviceRename-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the device's current name matches <Client> naming standard.
If it does not, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DeviceRename-Detection.log"
$DeviceNamePrefix = #<Client Prefix here>

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile

function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-Host $LogMessage
}

#------------------------------ Gather device information --------------------------------#

WriteLog "Gathering device information"
$details = Get-ComputerInfo
$CurrentDeviceName = $details.CsName
$matchFound = $false

#------------------------------- Generate Expected Name -----------------------------------#

$systemEnclosure = Get-CimInstance -ClassName Win32_SystemEnclosure
if (($null -eq $systemEnclosure.SMBIOSAssetTag) -or ($systemEnclosure.SMBIOSAssetTag -eq "")) {
    WriteLog "No BIOS Asset tag detected, using serial number for device name."
    # Stupid PowerShell 5.1 bug
    if ($null -ne $details.BiosSerialNumber) {
        $assetTag = $details.BiosSerialNumber
    } else {
        $assetTag = $details.BiosSeralNumber
    }
} else {
    $assetTag = $systemEnclosure.SMBIOSAssetTag
    WriteLog "BIOS Asset tag detected, using BIOS asset tag for device name."
}
if ($assetTag.Length -gt 11) {
    $assetTag = $assetTag.Substring(0, 11)
    WriteLog "Asset Tag longer than 11 characters, shortening."
}

$newName = $DeviceNamePrefix+$assetTag
WriteLog "Device name should be $newName."

#------------------------- Compare Expected and Current Name --------------------------------#

if ($newName -eq $CurrentDeviceName) {
    WriteLog "Current device name $CurrentDeviceName matches generated device name $newName."
    $matchFound = $true
}

#------------------------ Determine next steps based on name ------------------------------#

if ($matchFound -eq $false) {
    WriteLog ("Device name $CurrentDeviceName is incorrect, proceeding with device rename.")
    Stop-Transcript
    exit 1
}
if ($matchFound -eq $true) {
    WriteLog ("Match Found, exiting script")
    Stop-Transcript
    exit 0
}