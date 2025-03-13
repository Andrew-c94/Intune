<#
Script Name: EnableNumLock-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether Num Lock is enabled for the current user.
If it is disabled, the script exits with an exit code of 1 to trigger Intune to run the remediation script and enable it.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\EnableNumLock-Detection.log"
$Key = "HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
$ValueName = "InitialKeyboardIndicators"
$ExpectedValue = "2"
#This sets Num Lock to enabled state.

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-Host $LogMessage
}

#-------------------------------- Check Num Lock Status ----------------------------------#

$matchFound = $false

# Check for existence of registry key and specific value
if (Test-Path $key) {
   $value = Get-ItemProperty -Path $key -Name $valueName -ErrorAction SilentlyContinue
   if ($null -ne $value -and $value.$valueName -eq $expectedValue) {
      WriteLog "Registry key $key with value $valueName=$expectedValue found."
      $matchFound = $true
      }
}

# Exit script if a match is found
if ($matchFound -eq $false) {
    WriteLog ("Value $valueName=$expectedValue does not exist, proceeding with script to set value")
    Stop-Transcript
    exit 1
}
if ($matchFound -eq $true) {
    WriteLog ("Match Found, exiting script")
    Stop-Transcript
    exit 0
}