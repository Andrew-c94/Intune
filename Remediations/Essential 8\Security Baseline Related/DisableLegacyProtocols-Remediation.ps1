<#
Script Name: DisableLegacyProtocols-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether SSL3.0 and RC4 are set correctly (disabled).
Description: This is a remediation script used with remediations to disable legacy protocols such as SSL3.0 and RC4 that are not
currently available in the Intune settings catalog.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableLegacyProtocols-Remediation.log"
$RequiredDisableLegacyProtocolSettings = @(
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
    Name = "Enabled"
    RequiredValue = "0"
    # Sets the 'SSL 3.0 Server' setting to disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
    Name = "DisabledByDefault"
    RequiredValue = "1"
    # Sets the 'SSL 3.0 Server' setting to disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
    Name = "Enabled"
    RequiredValue = "0"
    # Sets the 'SSL 3.0 Client' setting to disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
    Name = "DisabledByDefault"
    RequiredValue = "1"
    # Sets the 'SSL 3.0 CLient' setting to disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128"
    Name = "Enabled"
    RequiredValue = "0"
    # Sets the 'RC4 40/128 Cipher' setting to disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128"
    Name = "Enabled"
    RequiredValue = "0"
    # Sets the 'RC4 56/128 Cipher' setting to disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 64/128"
    Name = "Enabled"
    RequiredValue = "0"
    # Sets the 'RC4 64/128 Cipher' setting to disabled
    },
    @{
    Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128"
    Name = "Enabled"
    RequiredValue = "0"
    # Sets the 'RC4 128/128 Cipher' setting to disabled
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

#------------------------------ Disable Legacy Protocols ----------------------------------#

# Set each registry key to the specified value
Try{
    ForEach ($Setting in $RequiredDisableLegacyProtocolSettings)
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
            WriteLog "Registry setting $Name at $Key is already set to $RequiredValue as expected."
        }
        else
        {
            New-ItemProperty -Path $Key -Name $Name -Value $RequiredValue -PropertyType DWORD -Force
            Writelog "$Name at $Key has been set to $RequiredValue successfully."
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