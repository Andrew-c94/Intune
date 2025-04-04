<#
Script Name: LanmanServerAutoDisconnect-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This detection script checks if the 'LanmanServer Auto Disconnect setting is set to 15', if it is not
it triggers the remediation script to run.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LanmanServerAutoDisconnect-Detection.log"
$Key = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
$ValueName = "autodisconnect"
$ExpectedValue = "15"
#This sets the 'autodisconnect' registry value not currently available via settings catalog in Intune.

#------------------------------------- Start log file -------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#------------------------ Detect LanmanServer Autodisconnect Status --------------------------#

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
    Writelog ("Value $valueName is not set to $expectedValue or does not exist, proceeding with script to set value.")
    Stop-Transcript
    exit 1
}
if ($matchFound -eq $true) {
    Writelog ("Match Found, exiting script.")
    Stop-Transcript
    exit 0
}