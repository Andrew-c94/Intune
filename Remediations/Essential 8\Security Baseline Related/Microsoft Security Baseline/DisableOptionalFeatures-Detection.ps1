<#
Script Name: DisableOptionalFeatures-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether legacy versions of PowerShell, .NET Framework and 
Internet Explorer are disabled.
If they are not, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableOptionalFeatures-Detection.log"
$OptionalFeatureChecks = @(

@{
	FeatureName = "MicrosoftWindowsPowerShellV2Root"
    ExpectedValue = "Disabled"
},
@{
	FeatureName = "NetFx3"
    ExpectedValue = "Disabled"
},
@{
	FeatureName = "Internet-Explorer-Optional-amd64"
    ExpectedValue = "Disabled"
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

#------------------------------- Check Feature Status -----------------------------------#

$FeatureActive = $null

# Check if any optional windows features are enabled
foreach ($check in $OptionalFeaturechecks) {

      $CheckFeatureDetails = Get-WindowsOptionalFeature -online -FeatureName $Check.FeatureName
      $CheckFeatureName = $CheckFeatureDetails.FeatureName
      $CheckFeatureState = $CheckFeatureDetails.State
      $CheckExpectedValue = $Check.ExpectedValue
    
    if ($CheckFeatureState -eq $CheckExpectedValue) {
            WriteLog "$CheckFeatureName is $CheckExpectedValue as required."
            $FeatureActive = $false
        }
        else {
        WriteLog "Check failed, $CheckFeatureName is $CheckFeatureState, continuing with remediation."
        Stop-Transcript
        Exit 1
        }
}


# Exit script without requiring Remediation if $FeatureActive is still $false
if ($FeatureActive -eq $false) {
    WriteLog "All Optional Features are disabled, exiting without further action."
    Stop-Transcript
    Exit 0
    }