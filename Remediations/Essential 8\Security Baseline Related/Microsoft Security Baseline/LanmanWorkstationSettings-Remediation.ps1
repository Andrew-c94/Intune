<#
Script Name: LanmanWorkstationSettings-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to set Lanman Workstation Settings that are not
currently available in the Intune settings catalog.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LanmanWorkstationSettings-Remediation.log"
$RequiredLanmanWorkstationSettings = @(
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\NetworkProvider"
    Name = "EnableMailslots"
    RequiredValue = ""
    # Sets the 'Enable remote mailslots' setting to disabled
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "RequireEncryption"
    RequiredValue = "0"
    # Sets the 'Require Encryption' setting to disabled
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation"
    Name = "MinSmb2Dialect"
    RequiredValue = "768"
    # Sets the 'Mandate the minimum version of SMB' setting to SMB 3.0.0
    },
    @{
    Key = "HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation"
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

#---------------------------- Set LanmanWorkstation Settings --------------------------------#

# Set each registry key to the specified value
Try{
    ForEach ($Setting in $RequiredLanmanWorkstationSettings)
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