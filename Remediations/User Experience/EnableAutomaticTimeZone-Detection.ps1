<#
Script Name: EnableAutomaticTimeZone-Detection.ps1
Version: 1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the time zone is set to automatic.
If it is not, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

#>

#------------------------------------ Set Variables -------------------------------------#
$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\EnableAutomaticTimeZone-Detection.log"
$KeystoCheck = @(
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate"
    Name = "Start"
    ExpectedValue = "3"
    }
)

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#------------------------------- Check Time Zone Settings ---------------------------------#

ForEach ($RegKey in $KeystoCheck)
{
    $Key = $RegKey.Key
    $Name = $RegKey.Name
    $ExpectedValue = $RegKey.ExpectedValue

    if (Test-Path $Key)
    {
        $Value = Get-ItemProperty -Path $Key -Name $Name -ErrorAction SilentlyContinue
        if ($Value.$Name -eq $ExpectedValue)
        {
            WriteLog "Registry setting $Name is already set to $ExpectedValue as expected."
        }
        else
        {
            WriteLog "Registry setting $Name is not set to $ExpectedValue, continuing to Remediation."
            Stop-Transcript
            Exit 1
        }
    }
    else {
        WriteLog "Registry key $Key does not exist, continuing to Remediation."
        Stop-Transcript
        Write-Host "Registry key $Key does not exist, continuing to Remediation."
        Exit 1
    }
}

WriteLog "Automatic Time Zone is already enabled, exiting script."
Stop-Transcript
Write-Host "Automatic Time Zone is already enabled, exiting script."
Exit 0

