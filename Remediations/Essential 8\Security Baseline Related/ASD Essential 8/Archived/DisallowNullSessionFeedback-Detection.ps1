This is now available in the LocalPoliciesSecurityOptions CSP for Windows 11 24H2 and up.

OMA-URI: ./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_AllowLocalSystemNULLSessionFallback
Format: int
Values: 0-1

https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-localpoliciessecurityoptions#networksecurity_allowlocalsystemnullsessionfallback


<#
Script Name: DisallowNullSessionFeedback-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This detection script checks if the 'Network security: Allow LocalSystem NULL session fallback' policy setting is disabled, if 
it is enabled it triggers the remediation script to run.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisallowNullSessionFeedback-Detection.log"
$Key = "HKLM:\System\CurrentControlSet\Control\LSA\MSV1_0"
$ValueName = "allownullsessionfallback"
$ExpectedValue = "0"
#This sets the 'Network security: Allow LocalSystem NULL session fallback' GPO setting not currently available via settings catalog in Intune.

#------------------------------------- Start log file -------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#----------------- Detect Allow LocalSystem NULL session fallback Status -------------------#

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