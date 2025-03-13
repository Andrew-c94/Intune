<#
Script Name: TempAdministratorLock-Enable.ps1
Version: 1

Description: This PowerShell script temporarily locks the Administrator account to protect it until the LAPS policy applies.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables ------------------------------------#

$ErrorActionPreference = "Stop"
$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\TempAdministratorLock-Enable.log"
$Username = "Administrator"
$Password = "<removed>"

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#------------------- Check Event Log for successful password backup ---------------------#

Writelog "Checking event log for successful LAPS password backup events."
$filter10018 = @{
    LogName = 'Microsoft-Windows-LAPS/Operational'
    Id = '10018' # LAPS Successfully updated Active Directory with a new password.
  }

$event10018 = Get-WinEvent -FilterHashtable $filter10018 -MaxEvents 1 -EA SilentlyContinue

If ($null -ne $event10018){
    Writelog "Successful password backup event found, exiting script with no further changes."
    Stop-Transcript
    Exit 0
}
else {
    Writelog "No successful LAPS password backup event found, setting temporary password."
}

#-----------------------------Set Password if no valid event found-----------------------------#
    Try {
        Writelog "Setting password for $Username."
        Set-LocalUser -Name $Username -Password (ConvertTo-SecureString $Password -AsPlainText -Force)
        Writelog "Password has been set, exiting script."
        Stop-Transcript
        exit 0
    }
    Catch {
        $errMsg = $_.Exception.Message
        return $errMsg
        Stop-Transcript
        Exit 1
    }