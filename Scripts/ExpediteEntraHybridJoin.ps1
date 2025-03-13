<#
Script Name: ExpediteEntraHybridJoin.ps1
Version: 1

Description: This PowerShell script checks whether there is a successful join entry in the event log for the device. If there is not, 
it sets the 'Automatic-Device-Join' scheduled task which triggers the device hybrid join process to run every 5 minutes for two hours.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$ErrorActionPreference = "Stop"
$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ExpediteEntraHybridJoin.log"
$TaskPath = "\Microsoft\Windows\Workplace Join\"
$TaskName = "Automatic-Device-Join"
$TaskRepetitionDuration = (New-TimeSpan -Hours 2)
$TaskRepetitionInterval = (New-TimeSpan -Minutes 5)

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#---------------------------- Check for successful join event-----------------------------#

Writelog "Checking event log for successful hybrid join events."
$filter306 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id = '306' # Automatic registration Succeeded
  }
    
$filter335 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id = '335' # Automatic device join pre-check tasks completed. The device is already joined.
  }

$event306 = Get-WinEvent -FilterHashtable $filter306 -MaxEvents 1 -EA SilentlyContinue
$event335 = Get-WinEvent -FilterHashtable $filter335 -MaxEvents 1 -EA SilentlyContinue

If ($null -ne $event335){
    Writelog "Device is already hybrid joined, not making any changes."
    Stop-Transcript
    Exit 0
}
elseif ($null -ne $event306){
    Writelog "Successful join event found, not making any changes."
    Stop-Transcript
    Exit 0
}
else {
    Writelog "Cannot find any successful join entries in event log, continuing with script."
}

#-------------------------------- Update Scheduled Task --------------------------------#

Writelog "Updating $TaskName scheduled task."
Try {
$Triggers = @()
$Triggers += (Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName).Triggers
$Triggers += New-ScheduledTaskTrigger -At (get-date) -Once -RepetitionDuration $TaskRepetitionDuration -RepetitionInterval $TaskRepetitionInterval
Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Trigger $Triggers
Writelog "Scheduled task updated successfully."
Stop-Transcript
Exit 0
}
Catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Stop-Transcript
    Exit 1
}