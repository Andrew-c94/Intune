<#
Script Name: EnableAutomaticTimeZone-Remediation.ps1
Version: 1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to enable automatic time zone.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$KeystoCheck = @(
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate"
    Name = "Start"
    RequiredValue = "3"
    }
)

$ErrorActionPreference = "Stop"

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#----------------------------- Enable Automatic Time Zone ---------------------------------#

# Set each registry key to the specified value
Try{
    ForEach ($RegKey in $KeystoCheck)
    {
        $Key = $RegKey.Key
        $Name = $RegKey.Name
        $RequiredValue = $RegKey.RequiredValue
    
        if (-NOT (Test-Path $Key)) {
        WriteLog "Registry path doesnt currently exist, creating $Key."    
        New-Item -Path $Key -Force | Out-Null
        WriteLog "New path created successfully."
        }
        
        $Value = Get-ItemProperty -Path $Key -Name $Name -ErrorAction SilentlyContinue
        if ($Value.$Name -eq $RequiredValue)
        {
            WriteLog "Registry setting $Name is already set to $RequiredValue as expected."
        }
        else
        {
            New-ItemProperty -Path $Key -Name $Name -Value $RequiredValue -PropertyType DWORD -Force
            Writelog "$Name has been set to $RequiredValue successfully."
        }
    }
}
catch {
    $errMsg = $_.Exception.Message
    WriteLog "An error has occured. ERROR:'$errMsg'. Exiting Script."
    Stop-Transcript
    Exit 1
    }

WriteLog "All Registry values have been set successfully, exiting script."
Stop-Transcript
Exit 0