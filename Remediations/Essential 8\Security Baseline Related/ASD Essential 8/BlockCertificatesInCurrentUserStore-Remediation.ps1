<#
Script Name: BlockCertificatesInCurrentUserStore-Remediation.ps1
Version: 1

Description: This is a remediation script used with remediations which sets the 'Excel vbarequirelmtrustedpublisher registry setting'
to enabled.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\BlockCertificatesInCurrentUserStore-Remediation.log"
$Key = "HKCU:\Software\Policies\Microsoft\office\16.0\excel\security"
$ValueName = "vbarequirelmtrustedpublisher"
$Value = "1"
#This sets Excel to require certificates from trusted publisher in the machine store for VBA scripts as per the ACSC Office Hardening Recommendations.
#This setting is not currently available via settings catalogue in Intune.
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

#--------------------- Set vbarequirelmtrustedpublisher to enabled --------------------------#

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