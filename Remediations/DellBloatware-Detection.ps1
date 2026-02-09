<#
Script Name: DellBloatWare-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether Dell Bloatware is installed on Dell PCs.
If any of the listed apps are detected, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DellBloatWare-Detection.log"
# List of Dell Bloatware Apps to check
$UninstallPrograms = @(
    "Dell Command | Update"
    "Dell Command | Update for Windows Universal"
    "Dell Command | Update for Windows 10"
    "DellInc.DellCommandUpdate"
    "Dell Power Manager"
    "Dell Power Manager Service"
    "DellInc.DellPowerManager"
    "Dell Digital Delivery"
    "Dell Digital Delivery Services"
    "DellInc.DellDigitalDelivery"
    "Dell SupportAssist"
    "Dell.SupportAssistforPCs"   
    "DellInc.DellSupportAssistforPCs"
    "Dell SupportAssist Remediation"
    "Dell SupportAssist OS Recovery"
    "Dell SupportAssist OS Recovery Plugin for Dell Update"
    "Dell Core Services"
    "Dell Update - SupportAssist Update Plugin"
    "Dell OS Recovery Tool"
    "Dell Pair"
    "Dell Optimizer"
    "Dell Optimizer Service"
    "Dell Optimizer Core"
    "DellOptimizerUI"
    "DellInc.DellOptimizer"
    "Dell Trusted Device"
    "Dell Trusted Device Agent"
    "DellInc.PartnerPromo"
    "Dell Peripheral Manager"
    "Dell Display Manager 2.0"
    "Dell Display Manager 2.1"
    "Dell Display Manager 2.2"
    "Dell Display and Peripheral Manager"
)

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function Write-Log
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#--------------------------- Check for win32 based Dell Bloatware Apps ------------------------------#

# Get a list of installed applications from Programs and Features
$InstalledApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Where-Object { $null -ne $_.DisplayName } |
Select-Object DisplayName, UninstallString

foreach ($app in $UninstallPrograms) {
    if ($installedApps | Where-Object { $_.DisplayName -eq "$app"}) {
    write-log "Found Win32 based install of '$app', exiting and continuing to remediation."
    Stop-Transcript
    Write-Host "'$app' found, continuing to remediation."
    Exit 1
    }
else {
    write-log "'$app' not found."
}
}
write-log "No win32 based Dell Bloatware apps found, continuing to Appx based checks"


#----------------------------- Check for Appx based Dell Bloatware Apps ------------------------------#

    $AppxProvisionedPackages = Get-AppxProvisionedPackage -Online
    $AppxAllUsers = Get-AppxPackage -AllUsers
    foreach ($app in $UninstallPrograms) {

        if ($AppxProvisionedPackages | Where-Object { $_.DisplayName -eq "$app"}) {
            write-log "Found provisioned Appx package for '$app', exiting and continuing to remediation."
            Stop-Transcript
            write-host "'$app' found, continuing to remediation."
            Exit 1
        }
        else {
            write-log "No Provisioned Appx package found for '$app'."
        }

        if ($AppxAllUsers | Where-Object { $_.DisplayName -eq "$app"}) {
            write-log "Found -allusers Appx package for '$app', exiting and continuing to remediation."
            Stop-Transcript
            write-host "'$app' found, continuing to remediation."
            Exit 1
        }
        else {
            write-log "No -allusers AppxPackage found for '$app'."
        }
    }

write-log "No Dell Bloatware found on system, remediation not required."
Stop-Transcript
Write-Host "No Dell Bloatware found on system, remediation not required."
Exit 0