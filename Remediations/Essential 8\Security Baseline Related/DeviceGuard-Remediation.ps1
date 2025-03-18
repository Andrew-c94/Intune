<#
Script Name: DeviceGuard-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to set Device Guard Settings that are not
currently available in the Intune settings catalog.

Note: Kernel-mode Hardware-enforced Stack Protection is only available on Windows 11 22H2 and later and requires compatible
hardware to be enabled.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DeviceGuard-Remediation.log"
$RequiredDeviceGuardSettings = @(
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"
    Name = "ConfigureKernelShadowStacksLaunch"
    RequiredValue = "1"
    # Sets the 'Kernel-mode Hardware-enforced Stack Protection' setting to enabled
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

#------------------------------ Set DeviceGuard Settings ----------------------------------#

# Set each registry key to the specified value
Try{
    ForEach ($Setting in $RequiredDeviceGuardSettings)
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