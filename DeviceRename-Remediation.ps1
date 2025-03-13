<#
Script Name: DeviceRename-Remediation.ps1
Source Script Version: 1.3
Source Script Author: Michael Niehaus
Remediation Version: 2

Description: This is a remediation script used with remediations to detect whether the device's current name matches Roy Hill's naming standard.
If it does not, the script initiates the device renaming process using pre-defined logic. It will name the device using a prefix, T, L or D based on
whether a battery and touchscreen are detected. It will also check for Active Directory connectivity and only run if connectivity is present.
For this script to work successfully, the computer must have 'SELF' renaming rights in Active Directory.

The script was originally created by Michael Niehaus but has been modified to work with the Remediation process and to meet Roy Hill's requirements.

The script is provided "AS IS" with no warranties.
#>

#Set Variables
$DeviceNamePrefix = "RH"
$ErrorActionPreference='Stop'

# Start Transcript
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DeviceRename-Remediation.log"

Try {
# Stop script if device name prefix doesn't match the standard.
Write-Host "Gathering device information"
$details = Get-ComputerInfo
$TouchscreenPresent = ($null -ne (Get-PnpDevice | Where-Object {$_.FriendlyName -like "*touch screen*"}))
$BatteryPresent = ($null -ne (Get-CimInstance -ClassName Win32_Battery | Select-Object Caption))
Write-Host "Checking if current device name starts with $DeviceNamePrefix."
if (($DeviceNamePrefix -ne "") -and (-not $details.CsName.StartsWith($DeviceNamePrefix))) {
    Write-Host "Device name doesn't match specified prefix, stopping script. Prefix must be $DeviceNamePrefix, Current device name is $($details.CsName)."
    Stop-Transcript
    Exit 0
}

# Check if device is Hybrid Joined or Entra Only.
Write-Host "Checking device join type."
$isAD = $false
$isAAD = $false
$tenantID = $null
if ($details.CsPartOfDomain) {
    Write-Host "Device is joined to AD domain: $($details.CsDomain)."
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
        Write-Host "Device is joined to Entra tenant: $tenantID."
        $isAAD = $true
    } else {
        Write-Host "Not part of a Entra or AD, in a workgroup."
    }
}

# Make sure we have connectivity
$goodToGo = $true
if ($isAD) {
    $dcInfo = [ADSI]"LDAP://RootDSE"
    if ($null -eq $dcInfo.dnsHostName)
    {
        Write-Host "No connectivity to the domain, unable to rename at this point."
        Stop-Transcript
        Exit 1
    }
}

# Good to go, we can rename the computer
if ($goodToGo)
{
    # Get the new computer name: use the asset tag (maximum of 13 characters), or the 
    # serial number if no asset tag is available
    $systemEnclosure = Get-CimInstance -ClassName Win32_SystemEnclosure
    if (($null -eq $systemEnclosure.SMBIOSAssetTag) -or ($systemEnclosure.SMBIOSAssetTag -eq "")) {
        Write-Host "No BIOS Asset tag detected, using serial number for device name."
        # Stupid PowerShell 5.1 bug
        if ($null -ne $details.BiosSerialNumber) {
            $assetTag = $details.BiosSerialNumber
        } else {
            $assetTag = $details.BiosSeralNumber
        }
    } else {
        $assetTag = $systemEnclosure.SMBIOSAssetTag
        Write-Host "BIOS Asset tag detected, using BIOS asset tag for device name."
    }
    if ($assetTag.Length -gt 11) {
        $assetTag = $assetTag.Substring(0, 11)
        Write-Host "Asset Tag longer than 11 characters, shortening."
    }
    if ($TouchscreenPresent -eq $True -and $BatteryPresent -eq $True) {
        $newName = $DeviceNamePrefix+"T-$assetTag"
        Write-Host "Battery and touchscreen detected, device classed as tablet. New device name will be $newName"
    } 
    elseif ($TouchscreenPresent -eq $False -and $BatteryPresent -eq $True) {
        $newName = $DeviceNamePrefix+"L-$assetTag"
        Write-Host "Battery detected, device classed as Laptop. New device name will be $newName"
    } 
    else {
        $newName = $DeviceNamePrefix+"D-$assetTag"
        Write-Host "No Battery or touchscreen detected, device classed as Desktop. New device name will be $newName."
    }

    # Is the computer name already set?  If so, bail out
    if ($newName -ieq $details.CsName) {
        Write-Host "No need to rename computer, name is already set to $newName"
        Stop-Transcript
        Exit 0
    }

    # Set the computer name
    Write-Host "Renaming computer to $($newName)."
    Rename-Computer -NewName $newName -Force

    # If rename occurs during ESP, dont trigger reboot. If afterwards, trigger reboot.
    if ($details.CsUserName -match "defaultUser")
    {
        Write-Host "Exiting during ESP/OOBE, skipping reboot."
        Stop-Transcript
        Exit 0
    }
    else {
        Write-Host "Initiating a restart in 10 minutes."
        shutdown /g /t 600 /f /c "Restarting the computer in 10 minutes due to a computer name change. Save your work."
        Stop-Transcript
        Exit 0
    }
}
}
Catch {
    $errMsg = $_.Exception.Message
    Write-Host "ERROR: Renaming failed with error '$errMsg'. Exiting Script."
    return $errMsg
    Stop-Transcript
    Exit 1
}
# SIG # Begin signature block
# MIImgAYJKoZIhvcNAQcCoIImcTCCJm0CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD90f2JfM5yF9uq
# OTqMrRnvqNJPZcC5A3uv8yJmDCqBFKCCH4swggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggXCMIIDqqADAgECAhN5AAAADW/tvx95UrZEAAAAAAANMA0G
# CSqGSIb3DQEBCwUAMFAxCzAJBgNVBAYTAkFVMSIwIAYDVQQKExlSb3kgSGlsbCBI
# b2xkaW5ncyBQdHkgTHRkMR0wGwYDVQQDExRSb3kgSGlsbCBSU0EgUm9vdCBDQTAe
# Fw0yMjAyMTYwMzI2NTFaFw0yNzAyMTYwMzM2NTFaMGcxEjAQBgoJkiaJk/IsZAEZ
# FgJhdTETMBEGCgmSJomT8ixkARkWA2NvbTEXMBUGCgmSJomT8ixkARkWB3JveWhp
# bGwxIzAhBgNVBAMTGlJveSBIaWxsIFJTQSBFbnRlcnByaXNlIENBMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA132yT1e67QxkPbNrMYXKjtpfuufVbsJx
# XanJVWq0W6C6MRkAMZpNef4gZe8N1CS0LctgcvQXoNx1CH8d9Rzdmrq0x1xJMznj
# yypkxLx5iJ7Yxjue5RnkAH2gCKiLSuurik2Y7wEkLbgVEp2peUCHRCkD+ojZtvE9
# t6N/M0VrOA267B2hBHlRoqg+UgAPHV5w951sflVEmAqOWUF8oUjE1xJxQUF6gJ/0
# vrMtugk9ExeNjPJPXWDaJftShO9BC6wwpnpiGkVZYkmO/rNaqVVLULBe9hK58vWz
# GGOkD648MKht6v60OHXd1LvJRvoJxW60f8R77Fp5X+lWaKn5N8O3QQIDAQABo4IB
# fDCCAXgwDgYDVR0PAQH/BAQDAgEGMBAGCSsGAQQBgjcVAQQDAgEBMCMGCSsGAQQB
# gjcVAgQWBBTOy5TdiAGf550l0TMMPVxSwi2ZITAdBgNVHQ4EFgQUQBwj6B7Wk+XI
# KYkNAH3lw47H43MwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwEgYDVR0TAQH/
# BAgwBgEB/wIBADAfBgNVHSMEGDAWgBQve1K1VZMG2Icbb04TOBGAnHT/XTBDBgNV
# HR8EPDA6MDigNqA0hjJodHRwOi8vcGtpLnJveWhpbGwuY29tLmF1L2NybC9Sb3lI
# aWxsUlNBUm9vdENBLmNybDB7BggrBgEFBQcBAQRvMG0wPwYIKwYBBQUHMAKGM2h0
# dHA6Ly9wa2kucm95aGlsbC5jb20uYXUvY2VydC9Sb3lIaWxsUlNBUm9vdENBLmNy
# dDAqBggrBgEFBQcwAYYeaHR0cDovL3BraS5yb3loaWxsLmNvbS5hdS9vY3NwMA0G
# CSqGSIb3DQEBCwUAA4ICAQB2QhQ8zpGc5A5nnWc411Gw+ujISPYO/VlaBT7Z0ZK7
# giBheZe9JcKQ3oafNq0O3kWV9VF20ZB/IE0q+ee5h7wlfNqtgsyCHMDrSt7Ri8PD
# OxCkWpPDJPZhjqS8z6pl7Rcj6A8Vq65EYfrmsJV5aivXbmCRZmL9ZEcQNQ40iyl5
# uIDBaybU6AiaTJkWCoHz5n64zoNFlMvQZ7sm+s6cf64hcJK6LBUSqyGMP9R2b/R1
# P0sfcpruNfqBQBWldlt/yvkqu6kqUdBOKoWgGeZrhIbNAMPmSaCGBEsYDXaoxglv
# Tgu2O91biNA9jDPcBelovfv1EQPV3g9hCTcyNgxC+B9P5LMFL0GejcvPdYO7yTNT
# U+JduxKbnyQSILTzYMgddTr08J5zHxq0EaMoLqu7fg37NBJ0pC2peOCxr26SKLx9
# 6dbGFMeDmH4WsNlhCWXHFdiKy8okZynsN2CerM/6Sw/cR84913vVUchG3mfDfdiA
# BShMenSOJKbNQmsdyCYka2XvaUSCbc2RjZL5gm8w40XbSV6yaqimMcx7Ayw32mDZ
# Y8sk7yHLCKhMpJVsRUlMK1BvUI4IE11Tzz8aMK1dWjzSofd0BHnwNunRtrK5GhJ+
# wQOABgADcukXm3cxMoFeOVTWY5gdOsVCDDrHRsPy6qOjeBXvdAxTU0/tKKfXpUcH
# yjCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAw
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290
# IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBU
# cnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh
# 1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+Feo
# An39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1
# decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxnd
# X7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6
# Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPj
# Q2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlREr
# WHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JM
# q++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh
# 3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8j
# u2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnS
# DmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1Ud
# DgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzf
# Lmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# dwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAG
# A1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOC
# AgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp
# /GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40B
# IiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2d
# fNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibB
# t94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7
# T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZA
# myEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdB
# eHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnK
# cPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/
# pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yY
# lvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwgga8MIIEpKADAgEC
# AhALrma8Wrp/lYfG+ekE4zMEMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjQwOTI2
# MDAwMDAwWhcNMzUxMTI1MjM1OTU5WjBCMQswCQYDVQQGEwJVUzERMA8GA1UEChMI
# RGlnaUNlcnQxIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDI0MIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvmpzn/aVIauWMLpbbeZZo7Xo/ZEf
# GMSIO2qZ46XB/QowIEMSvgjEdEZ3v4vrrTHleW1JWGErrjOL0J4L0HqVR1czSzvU
# Q5xF7z4IQmn7dHY7yijvoQ7ujm0u6yXF2v1CrzZopykD07/9fpAT4BxpT9vJoJqA
# sP8YuhRvflJ9YeHjes4fduksTHulntq9WelRWY++TFPxzZrbILRYynyEy7rS1lHQ
# KFpXvo2GePfsMRhNf1F41nyEg5h7iOXv+vjX0K8RhUisfqw3TTLHj1uhS66YX2LZ
# PxS4oaf33rp9HlfqSBePejlYeEdU740GKQM7SaVSH3TbBL8R6HwX9QVpGnXPlKdE
# 4fBIn5BBFnV+KwPxRNUNK6lYk2y1WSKour4hJN0SMkoaNV8hyyADiX1xuTxKaXN1
# 2HgR+8WulU2d6zhzXomJ2PleI9V2yfmfXSPGYanGgxzqI+ShoOGLomMd3mJt92nm
# 7Mheng/TBeSA2z4I78JpwGpTRHiT7yHqBiV2ngUIyCtd0pZ8zg3S7bk4QC4RrcnK
# J3FbjyPAGogmoiZ33c1HG93Vp6lJ415ERcC7bFQMRbxqrMVANiav1k425zYyFMyL
# NyE1QulQSgDpW9rtvVcIH7WvG9sqYup9j8z9J1XqbBZPJ5XLln8mS8wWmdDLnBHX
# gYly/p1DhoQo5fkCAwEAAaOCAYswggGHMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMB
# Af8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAGA1UdIAQZMBcwCAYGZ4EM
# AQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6FtltTYUvcyl2mi91jGogj57I
# bzAdBgNVHQ4EFgQUn1csA3cOKBWQZqVjXu5Pkh92oFswWgYDVR0fBFMwUTBPoE2g
# S4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNB
# NDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYIKwYBBQUHAQEEgYMwgYAw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBYBggrBgEFBQcw
# AoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0
# UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOC
# AgEAPa0eH3aZW+M4hBJH2UOR9hHbm04IHdEoT8/T3HuBSyZeq3jSi5GXeWP7xCKh
# VireKCnCs+8GZl2uVYFvQe+pPTScVJeCZSsMo1JCoZN2mMew/L4tpqVNbSpWO9QG
# FwfMEy60HofN6V51sMLMXNTLfhVqs+e8haupWiArSozyAmGH/6oMQAh078qRh6wv
# JNU6gnh5OruCP1QUAvVSu4kqVOcJVozZR5RRb/zPd++PGE3qF1P3xWvYViUJLsxt
# vge/mzA75oBfFZSbdakHJe2BVDGIGVNVjOp8sNt70+kEoMF+T6tptMUNlehSR7vM
# +C13v9+9ZOUKzfRUAYSyyEmYtsnpltD/GWX8eM70ls1V6QG/ZOB6b6Yum1HvIiul
# qJ1Elesj5TMHq8CWT/xrW7twipXTJ5/i5pkU5E16RSBAdOp12aw8IQhhA/vEbFkE
# iF2abhuFixUDobZaA0VhqAsMHOmaT3XThZDNi5U2zHKhUs5uHHdG6BoQau75KiNb
# h0c+hatSF+02kULkftARjsyEpHKsF7u5zKRbt5oK5YGwFvgc4pEVUNytmB3BpIio
# wOIIuDgP5M9WArHYSAR16gc0dP2XdkMEP5eBsX7bf/MGN4K3HP50v/01ZHo/Z5lG
# LvNwQ7XHBx1yomzLP8lx4Q1zZKDyHcp4VQJLu2kWTsKsOqQwgga+MIIFpqADAgEC
# AhMUAApWBpZQtAQYbmsHAAEAClYGMA0GCSqGSIb3DQEBCwUAMGcxEjAQBgoJkiaJ
# k/IsZAEZFgJhdTETMBEGCgmSJomT8ixkARkWA2NvbTEXMBUGCgmSJomT8ixkARkW
# B3JveWhpbGwxIzAhBgNVBAMTGlJveSBIaWxsIFJTQSBFbnRlcnByaXNlIENBMB4X
# DTI1MDEwOTAxMzkwMFoXDTI3MDEwOTAxMzkwMFowgasxEjAQBgoJkiaJk/IsZAEZ
# FgJhdTETMBEGCgmSJomT8ixkARkWA2NvbTEXMBUGCgmSJomT8ixkARkWB3JveWhp
# bGwxGjAYBgNVBAsTEVJveSBIaWxsIElyb24gT3JlMQ4wDAYDVQQLEwVVc2VyczET
# MBEGA1UECxMKUmVhbCBVc2VyczEOMAwGA1UECxMFUGVydGgxFjAUBgNVBAMTDVNp
# bW9uIE1hbnRlbGwwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDCmusD
# y2wQZuFeZE0dP2QaWqEB7UnBI2Z23w4q3DL+5XCE4Ym8+ngGQ4LsaB61T7IsaJTm
# /729V1btYTF1DgK/mcP8eAmFOTozuAczlXT3yuAAK5H1+d1DCcqixe4xXh4ghkD4
# HhQ5+BRPWN3vTQIM0eh5qtvEk6u/EZ1ocasRTIQ0b0ZImCKXhxIoO938aqdhCcLf
# zkMuxjKiEpVipPXTm9HbgaeDcAJV+AsBr16Il8PHuntV3JgTKVIUM8DSbO0Yts0b
# +AOkfvgltulv2Lz3bDLGJpNUeCX5igteHVu8gcM+ItJ052RQTDv1QIUQmLfXSO31
# rB1wCJu21QHUibYI+xcN47gV4asioowV0gcgVXYTRJ75u63ZKSkxk2jhuasw5rwu
# JudnPU9P7Jf8qAKdvxovPy8XmooUYaAThhYY0k9w5yk7B/1VW3oRU2wJNOfRS+gC
# 0gtgIDZmqMR2c+bzbvKQy4yfm/FdOhesRl6FwTBP2KAucvwNDZiyC32Pka1aEQYq
# 0gsqg8qQ6ZPQgCpSxSr8ddyCrYbv97W+Celq2Z17PMQmN5Jvz/KEeV2RDH5de4e7
# TYn1eItcJZiXafJTLTcWTPPXQpSkV/Oyd4uzs/DaclNwtfiN0FX+dfr7ztV/4QEC
# VJjVm6QWHuhoiOZEr2fXCWbznLS84Uimc6JxPQIDAQABo4ICHDCCAhgwOgYJKwYB
# BAGCNxUHBC0wKwYjKwYBBAGCNxUIhuGEfYK5/Au1ixeHyvFzg5r1SRTb4TzaiWQC
# AWQCAQQwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMBsGCSsG
# AQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFB4gP74KWV9rOzWCxTK3
# dh8MCr2NMB8GA1UdIwQYMBaAFEAcI+ge1pPlyCmJDQB95cOOx+NzMEkGA1UdHwRC
# MEAwPqA8oDqGOGh0dHA6Ly9wa2kucm95aGlsbC5jb20uYXUvY3JsL1JveUhpbGxS
# U0FFbnRlcnByaXNlQ0EuY3JsMIGBBggrBgEFBQcBAQR1MHMwRQYIKwYBBQUHMAKG
# OWh0dHA6Ly9wa2kucm95aGlsbC5jb20uYXUvY2VydC9Sb3lIaWxsUlNBRW50ZXJw
# cmlzZUNBLmNydDAqBggrBgEFBQcwAYYeaHR0cDovL3BraS5yb3loaWxsLmNvbS5h
# dS9vY3NwMDcGA1UdEQQwMC6gLAYKKwYBBAGCNxQCA6AeDBxzaW1vbi5tYW50ZWxs
# QHJveWhpbGwuY29tLmF1MFAGCSsGAQQBgjcZAgRDMEGgPwYKKwYBBAGCNxkCAaAx
# BC9TLTEtNS0yMS00MTg5ODIxMTMyLTEyMjc5NjA1MzgtNDI4ODc2MTA1NC03MjE0
# MzANBgkqhkiG9w0BAQsFAAOCAQEAgDQqvPFcCfc1NybMzkvW4FjBUc4n0l2/6hy3
# x10QQoaB3rBECXI4lrCvxDmkvmBqSjZg8WymDqFs3XPdHi5yZU+Yfnsyxf5W/jOX
# e5dvY4D/j6mOLuDEhtaKwEvNLVInQnZDmZBE4ZozSayRZDmmGCpIYWzLeLDCfvnq
# 0iFmt9+RuNM7QtXHtRgpLSAwo7TFEvmCdD//t+xDPwwPYlv124OoWutjkqqiVLbe
# T8g5hNhFL6HH9VkD/n+UknDEehH7IsIlNA9bST+zU0nWo1Bh4hPeWckgx6mkpinN
# tObwZB0VCcpSlE1w5k2ZUlQ0LK3Uy56swFoiEJgTtG/6ed4etTGCBkswggZHAgEB
# MH4wZzESMBAGCgmSJomT8ixkARkWAmF1MRMwEQYKCZImiZPyLGQBGRYDY29tMRcw
# FQYKCZImiZPyLGQBGRYHcm95aGlsbDEjMCEGA1UEAxMaUm95IEhpbGwgUlNBIEVu
# dGVycHJpc2UgQ0ECExQAClYGllC0BBhuawcAAQAKVgYwDQYJYIZIAWUDBAIBBQCg
# fDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAc
# BgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgfHSS
# jaDCbw7526q/plalJAONVbGD8ZbQtJuXtChGB0owDQYJKoZIhvcNAQEBBQAEggIA
# iLVf6J0KSKt71w3gMbNcL2FiqaZ1RsrE5MPHyyL4iO6/FBmyvvvIg9WkkUfdJ7ue
# i0tMOXtBJhUoLsyuGy2JyvMGeGj3L2OmCyUGcs54YUA4jigbJpaHHUEwpCzLlf3c
# RxgZno/lSgJ9hxUGwcL/TZ20O2/LKBEenO3BEw+LljVCw2rrUCA0DQWM1XFUUUdE
# FJn1kTqtL+3lvJ3x5m8AF2VyV5apJ9LD2gWMnI7DRPNxJcqNluVxazL6/MkSVRxS
# Zg3kci8huvw/alp0l7c6Tk9lwyFm6Y9i6wb+Pd2GcH8ZvKrlPxm5Wb+4tNln8mKh
# LbfWxat2re5m0AvURo5F/yOCLhTCLqT7j2IcEUtLQub4Glc5shyoXkaPy8G4J7bT
# wEXQh201Tl6ZTr81Ff2WecXGyJ33PRFSv9JipfBvwcKPTvmKiZuARo7Vx56WGOBI
# bHaF1GGWKFjB2FEGUx3262nMKDjRgFIyEXA7AeFLo1Ke7LNgFv3Bs2SUQWus2Y2P
# QaA4RcfXDuGYk0XUQJfojt6g1QLooIHfX58p7i9YCKVL7yd/mCpiyD9vHKwKUnkT
# lIlPdiy1pqQBIFFqb4pE5fFq9/MGHnmhkW1mjr1y3+WTWmY1VRAGj15KWPISTr98
# iaGyDv59rikSXEdGetZDTYRp+d9Vm4xOtJplPBq5ccyhggMgMIIDHAYJKoZIhvcN
# AQkGMYIDDTCCAwkCAQEwdzBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNl
# cnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBT
# SEEyNTYgVGltZVN0YW1waW5nIENBAhALrma8Wrp/lYfG+ekE4zMEMA0GCWCGSAFl
# AwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUx
# DxcNMjUwMzEzMDg0NDI3WjAvBgkqhkiG9w0BCQQxIgQg0luowvStgwSy+XJuWgyv
# L5fUr3x9DFMo8NlfXY0cnVIwDQYJKoZIhvcNAQEBBQAEggIAnsOIh4hMVtczy/VU
# lalvOvT3eo8pjDwDx90Ks5qdS0VW+TcMQc4xJ+s8yax93L0d/eTNCzBS+p/6h7Fx
# oaSJjkiOWY0PaMRcXe0/pzUo3VWnV7fhVZgDGyPFyT/rn3MoQ1V5qeFYUCsM5IEG
# vzsAqe5MSXvNekkOQf5MSx71THsLiyv+JbJuD3fYFlbgk26JGD14UG+QIXy/2dhW
# DDOj7Uf15/ItcBVc4vjh/9jNRKLxtSP1dRfPPzS5ZoRxAOudNS48md2IAjFlxx/o
# n+h4/46HW6ItpWadkgc01Gprg+VA62s8Thttvnjii8zt1NIQAhEccTKLqzs+sVbW
# RxlMTCsb5wmW24u5ClwNrsHMnfrkP5a1/wT5rPDfseK7XNgdZZqBazelDIebS5dT
# 8HRx8ahsCkXAAwHrTVFJelkmJefh7MlLJ12TsWTiiHcJZrtLP1Vh2MZS0KZ3f2g+
# SD04wHrZBBCE9tSynbK7wWZWXwm6IW2+NhJ+m3oyDrrUEzCBEOvkc98/mgY1Acsm
# nFTl9ABHWvsvfsrgm5Dloknu2A5R4/5XIYrghYq4zthQU0peKAOgYtQKleVj9m01
# 7NyGuLZfxRruVgdf5eU3Z0BpKrk1srqe+zfMc5CLxr2mOi3wQqbemrlJhNPoixoj
# tq1rd0x1GA7aw7E3OA0CSNdVd8w=
# SIG # End signature block
