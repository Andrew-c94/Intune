<#
Script Name: PreventActivationofOLE-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the Activation of OLE packages is prevented.
If any settings are not set correctly, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PreventActivationofOLE-Detection.log"
$RegistryChecks = @(
@{
	Key = "HKCU:\Software\Microsoft\Office\16.0\Excel\Security"
	ValueName = "PackagerPrompt"
	ExpectedValue = "2"
},
@{
	Key = "HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Security"
	ValueName = "PackagerPrompt"
	ExpectedValue = "2"
},
@{
	Key = "HKCU:\Software\Microsoft\Office\16.0\Word\Security"
	ValueName = "PackagerPrompt"
	ExpectedValue = "2"
}
)

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-Host $LogMessage
}

#------------------------- Check LanmanWorkstation Settings ------------------------------#

$ValueMissing = $null

# Check for existence of registry key and specific value
foreach ($check in $registrychecks) {

        $checkkey = $Check.Key
        $CheckValueName = $Check.ValueName
        $CheckExpectedValue = $Check.ExpectedValue
    
    if (Test-Path $checkkey) {
        $value = Get-ItemProperty -Path $Checkkey -Name $CheckvalueName -ErrorAction SilentlyContinue
        if ($value.$CheckValueName -eq $CheckExpectedValue) {
            WriteLog "$CheckValueName at $checkkey is set to $CheckExpectedValue as required."
            $ValueMissing = $false
        }
        else {
        WriteLog "Check failed, $CheckValueName on $Checkkey is not set to $CheckExpectedValue"
        Stop-Transcript
        Exit 1
        }
    }
}


# Exit script if without requiring Remediation if $ValueMissing is still $false
if ($ValueMissing -eq $false) {
    WriteLog "All OLE settings are set correctly, exiting without further Action"
    Stop-Transcript
    Exit 0
    }