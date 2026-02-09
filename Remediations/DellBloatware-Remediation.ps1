<#
Script Name: DellBloatWare-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to remove Dell Bloatware from PCs if found.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DellBloatWare-Remediation.log"
# List of Dell Bloatware Apps to check for and remove
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
$ErrorActionPreference = 'Stop'

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#------------------------------- Remove Win32 based Dell Bloatware ---------------------------------#

Try {
# Get a list of installed applications from Programs and Features
$InstalledApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Where-Object { $null -ne $_.DisplayName } |
Select-Object DisplayName, UninstallString

foreach ($app in $UninstallPrograms) {
    if ($installedApps | Where-Object { $_.DisplayName -eq "$app"}) {
    write-log "Found Win32 based install of '$app', attempting uninstallation."
    $uninstallString = $app.UninstallString
    $displayName = $app.DisplayName
    if ($uninstallString -match "^msiexec*") {
        #MSI install, replace the I with an X and make it quiet
        $string2 = $uninstallString + " /quiet /norestart"
        $string2 = $string2 -replace "/I", "/X "
        }
        else {
        #Exe installer, run straight path
        $string2 = $uninstallString
        }
    Start-Process $string2
    write-log "$app uninstalled successfully."
    }
else {
    write-log "'$app' not found."
}
}
write-log "All win32 apps processed, continuing to Appx based checks"

#----------------------------- Remove Appx based Dell Bloatware Apps ------------------------------#

    $AppxProvisionedPackages = Get-AppxProvisionedPackage -Online
    $AppxAllUsers = Get-AppxPackage -AllUsers
    foreach ($app in $UninstallPrograms) {

        if ($AppxProvisionedPackages | Where-Object { $_.DisplayName -eq "$app"}) {
            write-log "Found provisioned Appx package for '$app', attempting uninstallation."
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app | Remove-AppxProvisionedPackage -Online
            write-log "$app uninstalled successfully."
        }
        else {
            write-log "No Provisioned Appx package found for '$app'."
        }

        if ($AppxAllUsers | Where-Object { $_.DisplayName -eq "$app"}) {
            write-log "Found -allusers Appx package for '$app', attempting uninstallation."
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            write-log "$app uninstalled successfully."
        }
        else {
            write-log "No -allusers AppxPackage found for '$app'."
        }
    }

write-log "Finished processing Dell Bloatware removal, exiting."
Stop-Transcript
Write-Host "Finished processing Dell Bloatware removal, exiting."
Exit 0
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Stop-Transcript
    Write-Host $errMsg
    Exit 1
}