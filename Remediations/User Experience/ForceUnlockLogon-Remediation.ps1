<#
Script Name: ForceUnlockLogon-Remediation.ps1
Version: 1

Description: This is a remediation script used with remediations which sets the 'Interactive logon: Require Domain Controller authentication to 
unlock workstation' policy setting to disabled.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ForceUnlockLogon-Remediation.log"
$Key = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
$ValueName = "ForceUnlockLogon"
$Value = "0"
#This sets the 'Interactive logon: Require Domain Controller authentication to unlock workstation' policy setting to disabled.
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

#------------------------------- Disable ForceUnlockLogon ----------------------------------#

#Check reg path exists and add it if not
If (-NOT (Test-Path $Key)) {
  New-Item -Path $Key -Force | Out-Null
}  
# Set reg value and catch errors if any
Try{
    New-ItemProperty -Path $Key -Name $ValueName -Value $Value -PropertyType DWORD -Force
    Writelog "Registry value has been added successfully"
    Stop-Transcript
    Exit 0
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Stop-Transcript
    Exit 1
}