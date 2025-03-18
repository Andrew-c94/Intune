<#
Script Name: LanmanServerSettings-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to set Lanman Server Settings that are not
currently available in the Intune settings catalog.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LanmanServerSettings-Remediation.log"
$RequiredLanmanServerSettings = @(
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "EnableAuthRateLimiter"
    RequiredValue = "1"
    # Sets the 'Enable authentication rate limiter' setting to enabled 
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "InvalidAuthenticationDelayTimeInMs"
    RequiredValue = "2000"
    # Sets the 'Set authentication rate limiter delay' setting to 2000 milliseconds
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "MinSmb2Dialect"
    RequiredValue = "768"
    # Sets the 'Mandate the minimum version of SMB' setting to SMB 3.0.0
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "MaxSmb2Dialect"
    RequiredValue = "785"
    # Sets the 'Mandate the maximum version of SMB' setting to SMB 3.1.1
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

#---------------------------- Set LanmanServer Settings --------------------------------#

# Set each registry key to the specified value
Try{
    ForEach ($Setting in $RequiredLanmanServerSettings)
    {
        $Key = $Setting.Key
        $Name = $Setting.Name
        $RequiredValue = $Setting.RequiredValue
    
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