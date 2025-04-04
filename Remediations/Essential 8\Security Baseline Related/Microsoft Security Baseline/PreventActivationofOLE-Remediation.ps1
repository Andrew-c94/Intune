<#
Script Name: PreventActivationofOLE-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This script is used with remediations to configure Macro Settings that are not
currently available in the Intune settings catalog.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PreventActivationofOLE-Remediation.log"
$RegistryChecks = @(
    @{
    Key = "HKCU:\Software\Microsoft\Office\16.0\Excel\Security"
    ValueName = "PackagerPrompt"
    ExpectedValue = "2"
    },
    @{
     Key = "HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Security"
    ValueName = "PackagerPrompt"
    ExpectedValue = "2"
    },
    @{
    Key = "HKCU:\Software\Microsoft\Office\16.0\Word\Security"
    ValueName = "PackagerPrompt"
    ExpectedValue = "2"
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

write-host $LogMessage
}

#---------------------------- Set OLE Activation Settings --------------------------------#

# Check for existence of registry key and specific value
Try{
    foreach ($Check in $RegistryChecks) {
    
            $checkkey = $Check.Key
            $CheckValueName = $Check.ValueName
            $CheckExpectedValue = $Check.ExpectedValue
    
        if (Test-Path $checkkey) {
            $value = Get-ItemProperty -Path $Checkkey -Name $CheckvalueName -ErrorAction SilentlyContinue
            if ($Value.$CheckvalueName -eq $CheckExpectedValue) {
            Write-Host "$CheckValueName at $Checkkey is set to $CheckExpectedValue as required."
            }
            else {
            New-ItemProperty -Path $Checkkey -Name $CheckValueName -Value $CheckExpectedValue -PropertyType DWORD -Force
            Write-Host "$CheckValueName on $Checkkey has been changed to $CheckExpectedValue"
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