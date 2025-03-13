<#
Script Name: DisableStickyKeys-Remediation.ps1
Version: 1

Description: This is a remediation script used with remediations to disable Sticky Keys for the current user.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$ErrorActionPreference = 'Stop'
$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableStickyKeys-Remediation.log"
#Define values to check
$Key = "HKCU:\Control Panel\Accessibility\StickyKeys"
$ValueName = "Flags"
$Value = "506"
#This sets Sticky Keys to a disabled state.

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-host $LogMessage
}

#------------------------------------- Main Script ---------------------------------------#

#Check reg path exists and add it if not
If (-NOT (Test-Path $Key)) {
  New-Item -Path $Key -Force | Out-Null
}  
# Set reg value and catch errors if any
Try{
    
    New-ItemProperty -Path $Key -Name $ValueName -Value $Value -PropertyType DWORD -Force
    
    Write-Host "Registry value has been added successfully"
    Stop-Transcript
    Exit 0
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Stop-Transcript
    Exit 1
}