<#
Script Name: DeviceRename-Remediation.ps1
Source Script Version: 1.3
Source Script Author: Michael Niehaus
Author: Andrew Currell (GIT:@Andrew-c94)

Description: This is a remediation script used with remediations to detect whether the device's current name matches <Client> naming standard.
If it does not, the script initiates the device renaming process using pre-defined logic. It will also check for Active Directory connectivity 
and only run if connectivity is present.
For this script to work successfully, the computer must have 'SELF' renaming rights in Active Directory.

The script was originally created by Michael Niehaus but has been modified to work with the Remediation process and to meet <Client> requirements.

The script is provided "AS IS" with no warranties.
#>

#------------------------------------ Set Variables -------------------------------------#

$ErrorActionPreference = 'Stop'
$logfile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DeviceRename-Remediation.log"
$DeviceNamePrefix = #<Name Prefix>

#------------------------------------ Start log file ------------------------------------#

Start-Transcript -Path $logfile
function WriteLog
{
Param ([string]$LogString)

$DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
$LogMessage = "$Datetime $LogString"

Write-Host $LogMessage
}

#------------------------------ Gather device information --------------------------------#

Try {

WriteLog "Gathering device information"
$details = Get-ComputerInfo
WriteLog "Checking if current device name starts with $DeviceNamePrefix."
if (($DeviceNamePrefix -ne "") -and (-not $details.CsName.StartsWith($DeviceNamePrefix))) {
    WriteLog "Device name doesn't match specified prefix, stopping script. Prefix must be $DeviceNamePrefix, Current device name is $($details.CsName)."
    Stop-Transcript
    Exit 0
}

#------------------------------- Check domain join status ---------------------------------#

WriteLog "Checking device join type."
$isAD = $false
$tenantID = $null
if ($details.CsPartOfDomain) {
    WriteLog "Device is joined to AD domain: $($details.CsDomain)."
    $isAD = $true
    $goodToGo = $false
} else {
    $goodToGo = $true
    if (Test-Path "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo") {
        $subKey = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
        $guids = $subKey.GetSubKeyNames()
        foreach($guid in $guids) {
            $guidSubKey = $subKey.OpenSubKey($guid);
            $tenantId = $guidSubKey.GetValue("TenantId");
        }
    }
    if ($null -ne $tenantID) {
        WriteLog "Device is joined to Entra tenant: $tenantID."
    } else {
        WriteLog "Not part of a Entra or AD, in a workgroup."
    }
}

#------------------------------- Check domain connectivity --------------------------------#

$goodToGo = $true
if ($isAD) {
    $dcInfo = [ADSI]"LDAP://RootDSE"
    if ($null -eq $dcInfo.dnsHostName)
    {
        WriteLog "No connectivity to the domain, unable to rename at this point."
        Stop-Transcript
        Exit 1
    }
}

#--------------------------------- Begin renaming process -----------------------------------#

if ($goodToGo)
{
    # Get the new computer name: use the asset tag (maximum of 13 characters), or the 
    # serial number if no asset tag is available
    $systemEnclosure = Get-CimInstance -ClassName Win32_SystemEnclosure
    if (($null -eq $systemEnclosure.SMBIOSAssetTag) -or ($systemEnclosure.SMBIOSAssetTag -eq "")) {
        WriteLog "No BIOS Asset tag detected, using serial number for device name."
        # Stupid PowerShell 5.1 bug
        if ($null -ne $details.BiosSerialNumber) {
            $assetTag = $details.BiosSerialNumber
        } else {
            $assetTag = $details.BiosSeralNumber
        }
    } else {
        $assetTag = $systemEnclosure.SMBIOSAssetTag
        WriteLog "BIOS Asset tag detected, using BIOS asset tag for device name."
    }
    if ($assetTag.Length -gt 11) {
        $assetTag = $assetTag.Substring(0, 11)
        WriteLog "Asset Tag longer than 11 characters, shortening."
    }
    
    $newName = $DeviceNamePrefix+$assetTag
    WriteLog "New device name will be $newName."
    

    # Is the computer name already set?  If so, bail out
    if ($newName -ieq $details.CsName) {
        WriteLog "No need to rename computer, name is already set to $newName"
        Stop-Transcript
        Exit 0
    }

    # Set the computer name
    WriteLog "Renaming computer to $($newName)."
    Rename-Computer -NewName $newName -Force

 #-------------------------------- Change C Drive Label to New Name --------------------------------#

 WriteLog "Updating C drive label to $newName."
 Set-Volume -DriveLetter "C" -NewFileSystemLabel $newName

 #--------------------------------- Trigger reboot is not in ESP -----------------------------------#

    if ($details.CsUserName -match "defaultUser")
    {
        WriteLog "Exiting during ESP/OOBE, skipping reboot."
        Stop-Transcript
        Exit 0
    }
    else {
        WriteLog "Initiating a restart in 10 minutes."
        shutdown /g /t 600 /f /c "Restarting the computer in 10 minutes due to a computer name change. Save your work."
        Stop-Transcript
        Exit 0
    }
}
}
Catch {
    $errMsg = $_.Exception.Message
    WriteLog "ERROR: Renaming failed with error '$errMsg'. Exiting Script."
    Stop-Transcript
    Exit 1
}