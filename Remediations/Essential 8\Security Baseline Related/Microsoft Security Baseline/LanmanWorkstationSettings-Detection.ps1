<#
Script Name: LanmanWorkstationSettings-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the LanmanWorkstation Settings that are
not currently available in the Intune Settings Catalog are set correctly.
If any settings are not set correctly, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LanmanWorkstationSettings-Detection.log"
$ExpectedLanmanWorkstationSettings = @(
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "AuditInsecureGuestLogon"
    ExpectedValue = "1"
    # Checks if the 'Audit insecure guest logon' setting is enabled
    },
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "AuditServerDoesNotSupportEncryption"
    ExpectedValue = "1"
    # Checks if the 'Audit server does not support encryption' setting is enabled
    },
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "AuditServerDoesNotSupportSigning"
    ExpectedValue = "1"
    # Checks if the 'Audit server does not support signing' setting is enabled
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\NetworkProvider"
    Name = "EnableMailslots"
    ExpectedValue = "0"
    # Checks if the 'Enable remote mailslots' setting is disabled
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "MaxSmb2Dialect"
    ExpectedValue = "785"
    # Checks if the 'Mandate the maximum version of SMB' setting is set to SMB 3.1.1
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "MinSmb2Dialect"
    ExpectedValue = "768"
    # Checks if the 'Mandate the minimum version of SMB' setting is set to SMB 3.0.0
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "RequireEncryption"
    ExpectedValue = "0"
    # Checks if the 'Require Encryption' setting is disabled
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

#------------------------- Check LanmanWorkstation Settings ------------------------------#

ForEach ($Setting in $ExpectedLanmanWorkstationSettings)
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

WriteLog ("All LanmanWorkstation Settings are set correctly, exiting script.")
Stop-Transcript
Exit 0