<#
Script Name: NAbleUpdateSettings-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether old update settings deployed by 
N-Able are still present on the device.
If old settings are found, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\NAbleUpdateSettings-Detection.log"
$Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#---------------------------- Check Windows Update Settings -------------------------------#

if (Test-Path $Key)
    {
        WriteLog "Registry key $Key still exists, continuing to Remediation."
        Stop-Transcript
        #Exit 1
    }
else {
WriteLog "Registry key $key has already been removed, exiting without further action."
    }

Stop-Transcript
Exit 0