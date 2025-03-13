<#
Script Name: AppxRemoval-Remediation.ps1
Script Version: 1

Description: This remediation removes unwanted pre-installed Appx packages from Windows devices.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$ErrorActionPreference = 'silentlycontinue'
$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppxRemoval-Remediation.log"
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

Write-Host $LogMessage
}

#---------------------------- Remove Unwanted Appx Packages ------------------------------#

$failedappxuninstall = $false

    foreach ($app in $UninstallAppxList) {
        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            try {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -AllUsers
            WriteLog "Removed provisioned Appx package for $app."
            }
            Catch {
                $errMsg = $_.Exception.Message
                WriteLog "ERROR: Provisioned Appx package removal failed."
                $failedappxuninstall = $true
                return $errMsg
            }
        }
        else {
            WriteLog "No Provisioned Appx package found for $app."
        }
        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            try {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            WriteLog "Removed Appx package for $app."
            }
            Catch {
                $errMsg = $_.Exception.Message
                WriteLog "ERROR: Appx package removal failed."
                $failedappxuninstall = $true
                return $errMsg
            }
        }
        else {
            WriteLog "No Appx package found for $app."
        }
    }

if ($failedappxuninstall -eq $false){
    WriteLog ("All unwanted Appx packages have been removed successfully.")
    Stop-Transcript
    Exit 0
}
else {
    WriteLog ("One or more apps failed to uninstall. Remediation will be reattempted.")
    Stop-Transcript
    Exit 1
}