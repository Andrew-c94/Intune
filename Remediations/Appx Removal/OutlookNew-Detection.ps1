<#
Script Name: OutlookNew-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This detection checks if Outlook (New) is present on a device. 
If its found it triggers the associated remediation to run.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OutlookNew-Detection.log"
$ErrorActionPreference = 'silentlycontinue'

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#-------------------------------- Detect Outlook (New) ----------------------------------#

if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like Microsoft.OutlookForWindows -ErrorAction SilentlyContinue) 
    {
    writelog "Provisioned Appx package for Outlook (New) found. Continuing to remediation."
    Stop-Transcript
    Exit 1
    }
else {
    writelog "No Provisioned Appx package found for Outlook (New)."
    }

if (Get-AppxPackage -allusers -Name Microsoft.OutlookForWindows -ErrorAction SilentlyContinue) 
    {
    writelog "Appx package for Outlook (New) found. Continuing to remediation."
    Stop-Transcript
    Exit 1
    }
else {
    writelog "No Appx package found for Outlook (New). Exiting script."
    }
Stop-Transcript
Exit 0