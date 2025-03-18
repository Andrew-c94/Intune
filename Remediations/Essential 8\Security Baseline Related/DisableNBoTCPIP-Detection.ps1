<#
Script Name: DisableNBoTCPIP-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This detection script checks all network interfaces present on the client and if it finds any with NetBIOS over TCP/IP enabled it triggers the remediation script to run.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableNBoTCPIP-Detection.log"
$Key = "HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
$ValueName = "NetbiosOptions"
$ExpectedValue = "2" #This disables NetBIOS.

#------------------------------------- Start log file -------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#----------------------------- Detect NetBIOS over TCP/IP Status -------------------------------#

#Null variables
$ValueMissing = $null
$Interfaces = $null
$Interface = $null

#Get all child items into array
$Interfaces = @(Get-ChildItem $Key)

# Check for existence of registry key and specific value
foreach ($Interface in $Interfaces) {
    $InterfacePath = Join-Path -Path $Key -ChildPath $Interface.PSChildName
    
    if (Test-Path $InterfacePath) {
        $value = Get-ItemProperty -Path $interfacePath -Name $valueName -ErrorAction SilentlyContinue
        if ($value.$ValueName -eq $expectedValue) {
            writelog "$ValueName at $interfacePath is set to $expectedValue as required."
            $ValueMissing = $false
        }
        else {
        writelog "Check failed, $ValueName on $Interface is not set to $ExpectedValue"
        Stop-Transcript
        Exit 1
        }
    }
}

# Exit script if without requiring Remediation if $ValueMissing is still $false
if ($ValueMissing -eq $false) {
    writelog "All interfaces have the correct NetBois setting, exiting without further Action"
    Stop-Transcript
    Exit 0
    }