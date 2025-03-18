<#
Script Name: DisableLegacyProtocols-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether SSL3.0 and RC4 are set correctly (disabled).
If they are set incorrectly, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.


The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableLegacyProtocols-Detection.log"
$ExpectedDisableLegacyProtocolSettings = @(
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
    Name = "Enabled"
    ExpectedValue = "0"
    # Checks if the 'SSL 3.0 Server' setting is disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
    Name = "DisabledByDefault"
    ExpectedValue = "1"
    # Checks if the 'SSL 3.0 Server' setting is disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
    Name = "Enabled"
    ExpectedValue = "0"
    # Checks if the 'SSL 3.0 Client' setting is disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
    Name = "DisabledByDefault"
    ExpectedValue = "1"
    # Checks if the 'SSL 3.0 CLient' setting is disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128"
    Name = "Enabled"
    ExpectedValue = "0"
    # Checks if the 'RC4 40/128 Cipher' setting is disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128"
    Name = "Enabled"
    ExpectedValue = "0"
    # Checks if the 'RC4 56/128 Cipher' setting is disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 64/128"
    Name = "Enabled"
    ExpectedValue = "0"
    # Checks if the 'RC4 64/128 Cipher' setting is disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128"
    Name = "Enabled"
    ExpectedValue = "0"
    # Checks if the 'RC4 128/128 Cipher' setting is disabled
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

#---------------------------- Check SSL3.0 and RC4 Settings -------------------------------#

ForEach ($Setting in $ExpectedDisableLegacyProtocolSettings)
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

WriteLog ("All legacy protocol settings are set correctly, exiting script.")
Stop-Transcript
Exit 0