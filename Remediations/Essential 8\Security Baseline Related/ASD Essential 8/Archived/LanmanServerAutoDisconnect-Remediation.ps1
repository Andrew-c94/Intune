<#
Script Name: LanmanServerAutoDisconnect-Remediation.ps1
Version: 1

Description: This is a remediation script used with remediations which sets the ''LanmanServer Auto Disconnect setting is set to 15'.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LanmanServerAutoDisconnect-Remediation.log"
$Key = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
$ValueName = "autodisconnect"
$Value = "15"
#This sets the 'autodisconnect' registry value not currently available via settings catalog in Intune.
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

#------------------------ Set LanmanServer Autodisconnect to 15 -----------------------------#

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