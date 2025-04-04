<#
Script Name: DisableOptionalFeatures-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This script is used with remediations to disable legacy versions of PowerShell, .NET Framework and 
Internet Explorer.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableOptionalFeatures-Remediation.log"
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
$ErrorActionPreference = "Stop"

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-Host $LogMessage
}

#--------------------------------- Disables Feature --------------------------------------#

#Disable Optional Windows Features
foreach ($check in $OptionalFeaturechecks) {

    $CheckFeatureDetails = Get-WindowsOptionalFeature -online -FeatureName $Check.FeatureName
    $CheckFeatureName = $CheckFeatureDetails.FeatureName
    $CheckFeatureState = $CheckFeatureDetails.State

  try {
  if ($CheckFeatureState -ne $Check.ExpectedValue) {
  Disable-WindowsOptionalFeature -Online -FeatureName $CheckFeatureName -NoRestart
  WriteLog "$CheckFeatureName has been disabled successfully."
  }
  else {
  WriteLog "$CheckFeatureName is already disabled."
  }
 }
  catch {
  $errMsg = $_.Exception.Message
  return $errMsg
  Stop-Transcript
  Exit 1
  }
  }

Stop-Transcript
Exit 0