<#
Script Name: LSAAnonymousNameLookup-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations which disables the 'Network access: Allow anonymous SID/Name translation'
security policy setting.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\LSAAnonymousNameLookup-Remediation.log"
$LSAAnonymousNameLookupName = "LSAAnonymousNameLookup"
$LSAAnonymousNameLookupStatus = $(Get-Content $env:temp/secexport.cfg | Select-String $LSAAnonymousNameLookupName).ToString().Split('=')[1].Trim()
$LSAAnonymousNameLookupValue = "0"
#This sets the 'Network access: Allow anonymous SID/Name translation' policy setting is disabled.
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

#---------------------------------- Remediate LSA Status ----------------------------------#

#Export Security Policy
secedit /export /cfg $env:temp/secexport.cfg

# Check for existence of the policy setting in the local security policy and specific value
if ($LSAAnonymousNameLookupStatus -ne $LSAAnonymousNameLookupValue) {
    
    # Update Security Policy and catch errors if any
    Try{
        (Get-Content $env:temp/secexport.cfg).replace("$LSAAnonymousNameLookupName = $LSAAnonymousNameLookupStatus", "$LSAAnonymousNameLookupName = $LSAAnonymousNameLookupValue") | Out-File $env:temp/secexport.cfg
        secedit /configure /db c:\windows\security\local.sdb /cfg $env:temp/secexport.cfg /areas SECURITYPOLICY
        Remove-Item $env:temp/secexport.cfg -force
        writelog "Security Policy has been updated successfully"
        Stop-Transcript
        Exit 0
    }
    catch {
        $errMsg = $_.Exception.Message
        return $errMsg
        Stop-Transcript
        Exit 1
    }
}
