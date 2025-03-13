<#
Script Name: SoftwareCenterShortcut-Detection.ps1
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a detection script used with remediations to detect whether the shortcut for MECM Software Center is visible in the start menu.
If it is, the script exits with an exit code of 1 to trigger Intune to continue with the remediation script.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\SoftwareCenterShortcut-Detection.log"
$Shortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Configuration Manager\Configuration Manager\Software Center.lnk"
$ExpectedAttributes = 'NotContentIndexed','hidden'
#This checks if the Software Center shortcut is visible in the start menu and proceeds to a remediation script to hide it if it is.

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

write-host $LogMessage
}

#----------------------- Check Software Centre Shortcut Visibility -------------------------#

$matchFound = $false

# Check the file attributes of the shortcut
$ShortcutDetails = (Get-Item $Shortcut -force)
$ShortcutStatus = $ShortcutDetails.Attributes
if ($ShortcutStatus -eq $ExpectedAttributes) {
      writelog "Shortcut has been hidden as expected."
      $matchFound = $true
}

# Exit script if a match is found
if ($matchFound -eq $false) {
    writelog "Software Center shortcut is still visible, proceeding to hide."
    Stop-Transcript
    exit 1
}
if ($matchFound -eq $true) {
    writelog ("Software Center shortcut hidden as expected, exiting script")
    Stop-Transcript
    exit 0
}
