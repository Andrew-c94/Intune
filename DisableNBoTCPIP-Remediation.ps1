<#
Script Name: DisableNBoTCPIP-Remediation.ps1
Remediation Version: 1

Description: This remediation script checks all network interfaces present on the client and if it finds any with NetBIOS over TCP/IP enabled it disables it.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DisableNBoTCPIP-Remediation.log"
$Key = "HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
$ValueName = "NetbiosOptions"
$NewValue = "2" #This disables NetBIOS.
$ErrorActionPreference = 'stop'

#------------------------------------- Start log file -------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#-------------------------------- Disable NetBIOS over TCP/IP ----------------------------------#

#Null variables
$Interfaces = $null
$Interface = $null

#Get all child items into array
$Interfaces = @(Get-ChildItem $Key)

# Check for existence of registry key and specific value
Try{
foreach ($Interface in $Interfaces) {
    $InterfacePath = Join-Path -Path $Key -ChildPath $Interface.PSChildName
    
    if (Test-Path $InterfacePath) {
        $value = Get-ItemProperty -Path $InterfacePath -Name $valueName -ErrorAction SilentlyContinue
        if ($value.valueName -eq $NewValue) {
        writelog "$ValueName at $interfacePath is set to $NewValue as required."
        }
        else {
        New-ItemProperty -Path $InterfacePath -Name $ValueName -Value $NewValue -PropertyType DWORD -Force
        writelog "$ValueName on $Interface has been changed to $NewValue"
        }
      }
    }
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Stop-Transcript
    Exit 1
    }

Stop-Transcript
Exit 0