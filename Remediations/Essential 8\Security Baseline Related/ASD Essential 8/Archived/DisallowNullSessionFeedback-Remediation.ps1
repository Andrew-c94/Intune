This is now available in the LocalPoliciesSecurityOptions CSP for Windows 11 24H2 and up.

OMA-URI: ./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_AllowLocalSystemNULLSessionFallback
Format: int
Values: 0-1

https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-localpoliciessecurityoptions#networksecurity_allowlocalsystemnullsessionfallback

<#
Script Name: DisallowNullSessionFeedback-Remediation.ps1
Version: 1

Description: This is a remediation script used with remediations which sets the 'Network security: Allow LocalSystem NULL session fallback'
policy setting to disabled.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisallowNullSessionFeedback-Remediation.log"
$Key = "HKLM:\System\CurrentControlSet\Control\LSA\MSV1_0"
$ValueName = "allownullsessionfallback"
$Value = "0"
#This sets the 'Network security: Allow LocalSystem NULL session fallback' GPO setting not currently available via settings catalog in Intune.
$ErrorActionPreference = 'stop'

#------------------------------------- Start log file -------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-host $LogMessage
}

#------------------ Disable Allow LocalSystem NULL session fallback -----------------------#

#Check reg path exists and add it if not
If (-NOT (Test-Path $Key)) {
  New-Item -Path $Key -Force | Out-Null
}  
# Set reg value and catch errors if any
Try{
    New-ItemProperty -Path $Key -Name $ValueName -Value $Value -PropertyType DWORD -Force
    Writelog "Registry value has been added successfully."
    Stop-Transcript
    Exit 0
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Stop-Transcript
    Exit 1
}