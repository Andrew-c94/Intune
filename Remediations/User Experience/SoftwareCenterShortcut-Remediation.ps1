<#
Script Name: SoftwareCenterShortcut-Remediation.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to hide the Software Center shortcut from the start menu.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\SoftwareCenterShortcut-Remediation.log"
$Shortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Configuration Manager\Configuration Manager\Software Center.lnk"
$ExpectedAttributes = 'NotContentIndexed','hidden'
#This checks if the Software Center shortcut is present in the start menu and hides it if it is.
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

#---------------------------- Hide Software Centre Shortcut  ------------------------------#

# Check the file attributes of the shortcut
$ShortcutDetails = (Get-Item $Shortcut -force)
$ShortcutStatus = $ShortcutDetails.Attributes
if ($ShortcutStatus -ne $ExpectedAttributes) 
{
writelog "Hiding shortcut."

    # Set the shortcut to hidden
    Try{
        $ShortcutDetails.Attributes = $ExpectedAttributes
        writelog "Shortcut hidden successfully"
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
if ($ShortcutStatus -eq $ExpectedAttributes)
{
    writelog "Shortcut already hidden, no changes made."
    Stop-Transcript
    Exit 0
}
