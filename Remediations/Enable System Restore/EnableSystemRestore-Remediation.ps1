<#
Script Name: EnableSystemRestore-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations which enables system restore on devices if it is disabled.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\EnableSystemRestore-Remediation.log"
$ErrorActionPreference = 'Stop'

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#-------------------------------- Enable System Restore ----------------------------------#

Try{
    Enable-ComputerRestore -Drive C:\
    vssadmin resize shadowstorage /On=C: /For=C: /Maxsize=15GB
    
    writelog "System Restore enabled successfully."
    Stop-Transcript
    Exit 0
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Stop-Transcript
    Exit 1
}
