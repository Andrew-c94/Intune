<#
Script Name: AppxRemoval-Detection.ps1
Script Version: 1

Description: This detection checks if any unwanted pre-installed Appx packages are present on a device. 
If any are found it triggers the associated remediation to run.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$ErrorActionPreference = 'silentlycontinue'
$UninstallAppxList = @(
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.GamingApp"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.MicrosoftOfficeHub"
)

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppxRemoval-Detection.log"

#-------------------------------- Detect Appx Packages ----------------------------------#

    foreach ($app in $UninstallAppxList) {

        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Write-Host "Provisioned Appx package for $app found. Continuing to remediation."
            Stop-Transcript
            Exit 1
            }
        else {
            write-host "No Provisioned Appx package found for $app."
        }

        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            Write-Host "Appx package for $app found. Continuing to remediation."
            Stop-Transcript
            Exit 1
            }
        else {
            write-host "No Appx package found for $app."
        }

    }

write-host ("No unwanted Appx packages detected.")
Stop-Transcript
Exit 0