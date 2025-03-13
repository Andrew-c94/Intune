<#
Script Name: AppxRemoval-Detection.ps1
Script Version: 1

Description: This detection checks if any unwanted pre-installed Appx packages are present on a device. 
If any are found it triggers the associated remediation to run.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$ErrorActionPreference = 'silentlycontinue'
$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppxRemoval-Detection.log"
$UninstallAppxList = @(
    "Microsoft.BingWeather"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.Office.Onenote"
    "Microsoft.People"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.GamingApp"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
)

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-host $LogMessage
}

#-------------------------------- Detect Appx Packages ----------------------------------#

    foreach ($app in $UninstallAppxList) {

        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            WriteLog "Provisioned Appx package for $app found. Continuing to remediation."
            Stop-Transcript
            Exit 1
            }
        else {
            WriteLog "No Provisioned Appx package found for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            WriteLog "Appx package for $app found. Continuing to remediation."
            Stop-Transcript
            Exit 1
            }
        else {
            WriteLog "No Appx package found for $app."
        }
    }

WriteLog ("No unwanted Appx packages detected.")
Stop-Transcript
Exit 0