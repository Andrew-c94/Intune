<#
Script Name: ForceUnlockLogon-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the 'Interactive logon: Require Domain Controller authentication to 
unlock workstation' policy setting is disabled.
If it is not, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ForceUnlockLogon-Detection.log"
$Key = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
$ValueName = "ForceUnlockLogon"
$ExpectedValue = "0"
#This sets the 'Interactive logon: Require Domain Controller authentication to unlock workstation' policy setting to disabled.

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-host $LogMessage
}

#---------------------------- Detect ForceUnlockLogon Status -------------------------------#

$matchFound = $false

# Check for existence of registry key and specific value
if (Test-Path $key) {
   $value = Get-ItemProperty -Path $key -Name $valueName -ErrorAction SilentlyContinue
   if ($null -ne $value -and $value.$valueName -eq $expectedValue) {
      Writelog "Registry key $key with value $valueName=$expectedValue found."
      $matchFound = $true
      }
}

# Exit script if a match is found
if ($matchFound -eq $false) {
    Writelog ("Value $valueName=$expectedValue does not exist, proceeding with script to set value")
    Stop-Transcript
    exit 1
}
if ($matchFound -eq $true) {
    Writelog ("Match Found, exiting script")
    Stop-Transcript
    exit 0
}