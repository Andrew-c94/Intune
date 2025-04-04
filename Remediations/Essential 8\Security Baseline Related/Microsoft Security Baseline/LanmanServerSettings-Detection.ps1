<#
Script Name: LanmanServerSettings-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the LanmanServer Settings that are
not currently available in the Intune Settings Catalog are set correctly.
If any settings are not set correctly, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LanmanServerSettings-Detection.log"
$ExpectedLanmanServerSettings = @(
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
    Name = "AuditClientDoesNotSupportEncryption"
    ExpectedValue = "1"
    # Checks if the 'Audit client does not support encryption' setting is enabled
    },
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
    Name = "AuditClientDoesNotSupportSigning"
    ExpectedValue = "1"
    # Checks if the 'Audit client does not support signing' setting is enabled
    },
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
    Name = "AuditInsecureGuestLogon"
    ExpectedValue = "1"
    # Checks if the 'Audit insecure guest logon' setting is enabled
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "EnableAuthRateLimiter"
    ExpectedValue = "1"
    # Checks if the 'Enable authentication rate limiter' setting is enabled 
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\NetworkProvider"
    Name = "EnableMailslots"
    ExpectedValue = "0"
    # Checks if the 'Enable remote mailslots' setting is disabled
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "MaxSmb2Dialect"
    ExpectedValue = "785"
    # Checks if the 'Mandate the maximum version of SMB' setting is set to SMB 3.1.1
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "MinSmb2Dialect"
    ExpectedValue = "768"
    # Checks if the 'Mandate the minimum version of SMB' setting is set to SMB 3.0.0
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanServer"
    Name = "InvalidAuthenticationDelayTimeInMs"
    ExpectedValue = "2000"
    # Checks if the 'Set authentication rate limiter delay' setting is set to 2000 milliseconds
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

#---------------------------- Check LanmanServer Settings --------------------------------#

ForEach ($Setting in $ExpectedLanmanServerSettings)
{
    $Key = $Setting.Key
    $Name = $Setting.Name
    $ExpectedValue = $Setting.ExpectedValue

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
        Exit 1
    }
}

WriteLog ("All LanmanServer Settings are set correctly, exiting script.")
Stop-Transcript
Exit 0