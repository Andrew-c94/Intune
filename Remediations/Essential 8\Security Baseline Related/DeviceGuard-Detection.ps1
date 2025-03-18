<#
Script Name: EnableKernelShadowStacksLaunch-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the Kernel-mode Hardware-enforced Stack Protection
aetting within Device Guard that is not currently available in the Intune Settings Catalog is enabled.
If it is not set correctly, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

Note: Kernel-mode Hardware-enforced Stack Protection is only available on Windows 11 22H2 and later and requires compatible
hardware to be enabled.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\EnableKernelShadowStacksLaunch-Detection.log"
$ExpectedDeviceGuardSettings = @(
    @{
    Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"
    Name = "ConfigureKernelShadowStacksLaunch"
    ExpectedValue = "1"
    # Checks if the 'Kernel-mode Hardware-enforced Stack Protection' setting is enabled
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

#---------------------------- Check Device Guard Settings -------------------------------#

ForEach ($Setting in $ExpectedDeviceGuardSettings)
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

WriteLog ("All Device Guard Settings are set correctly, exiting script.")
Stop-Transcript
Exit 0