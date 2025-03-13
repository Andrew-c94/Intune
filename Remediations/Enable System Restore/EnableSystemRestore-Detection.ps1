<#
Script Name: EnableSystemRestore-Detection.ps1
Version: 1

Description: This is a detection script used with remediations to detect whether system restore is enabled.
If it is not, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\EnableSystemRestore-Detection.log"
$Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore\"
$ValueName = "RPSessionInterval"
$ExpectedValue = "1"
#This indicates that system restore is enabled.

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#----------------------------- Check System Restore Status -------------------------------#

$matchFound = $false

# Check for existence of registry key and specific value
if (Test-Path $key) {
   $value = Get-ItemProperty -Path $key -Name $valueName -ErrorAction SilentlyContinue
   if ($null -ne $value -and $value.$valueName -eq $expectedValue) {
      writelog "Registry key $key with value $valueName=$expectedValue found indicating System Restore is already enabled."
      $matchFound = $true
      }
}


# Exit script if a match is found
if ($matchFound -eq $false) {
    writelog ("Value $valueName=$expectedValue indicates system restore is currently disabled, proceeding with script to enable.")
    Stop-Transcript
    exit 1
}
if ($matchFound -eq $true) {
    writelog ("System Restore is already enabled, exiting script.")
    Stop-Transcript
    exit 0
}