<#
Script Name: AppxRemoval-Remediation.ps1
Script Version: 1

Description: This remediation removes unwanted pre-installed Appx packages from Windows devices.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$ErrorActionPreference = 'silentlycontinue'
$UninstallAppxList = @(
    "Microsoft.GetHelp"
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

Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppxRemoval-Remediation.log"

#---------------------------- Remove Unwanted Appx Packages ------------------------------#

$failedappxuninstall = $false

    foreach ($app in $UninstallAppxList) {

        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            try {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -AllUsers
            write-host "Removed provisioned Appx package for $app."
            }
            Catch {
                $errMsg = $_.Exception.Message
                Write-Host "ERROR: Provisioned Appx package removal failed."
                $failedappxuninstall = $true
                return $errMsg
            }

        }
        else {
            write-host "No Provisioned Appx package found for $app."
        }

        if (Get-AppxPackage -allusers -Name $app -ErrorAction SilentlyContinue) {
            try {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            write-host "Removed Appx package for $app."
            }
            Catch {
                $errMsg = $_.Exception.Message
                Write-Host "ERROR: Appx package removal failed."
                $failedappxuninstall = $true
                return $errMsg
            }
        }
        else {
            write-host "No Appx package found for $app."
        }

    }

if ($failedappxuninstall -eq $false){
    write-host ("All unwanted Appx packages have been removed successfully.")
    Stop-Transcript
    Exit 0
}
else {
    write-host ("One or more apps failed to uninstall. Remediation will be reattempted.")
    Stop-Transcript
    Exit 1
}