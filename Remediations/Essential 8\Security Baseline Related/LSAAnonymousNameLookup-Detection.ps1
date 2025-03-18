<#
Script Name: LSAAnonymousNameLookup-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the 'Network access: Allow anonymous SID/Name translation'
security policy is set to disabled.
If it is not, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LSAAnonymousNameLookup-Detection.log"
$LSAAnonymousNameLookupStatus = $(Get-Content $env:temp/secexport.cfg | Select-String "LSAAnonymousNameLookup").ToString().Split('=')[1].Trim()
$LSAAnonymousNameLookupValue = "0"
#This sets the 'Network access: Allow anonymous SID/Name translation' policy setting is disabled.

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#----------------------------------- Check LSA Status ---------------------------------------#

$matchFound = $false

#Export Security Policy
secedit /export /cfg $env:temp/secexport.cfg

# Check for existence of the policy setting in the local security policy and specific value
if ($null -ne $LSAAnonymousNameLookupStatus -and $LSAAnonymousNameLookupStatus -eq $LSAAnonymousNameLookupValue) {
    writelog "Local Security Policy setting with value $LSAAnonymousNameLookupValue found."
    $matchFound = $true
    }

# Exit script if a match is found
if ($matchFound -eq $false) {
    writelog ("Local Security Policy setting with value $LSAAnonymousNameLookupValue does not exist, proceeding with script to set value")
    Remove-Item $env:temp/secexport.cfg -force
    Stop-Transcript
    exit 1
}
if ($matchFound -eq $true) {
    writelog ("Match Found, exiting script")
    Remove-Item $env:temp/secexport.cfg -force
    Stop-Transcript
    exit 0
}

