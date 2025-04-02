# Logging Path
$global:LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"

#Minimum free disk space (GB)
$MinimumAvailableSpace = 35

# Start logging
$Timestamp = Get-Date -Format "yyyy-MM-dd_THHmmss"
Write-Host "Starting transcript logging to $LogPath\DiskCleanupLogs_$Timestamp-Detection.txt"
Start-Transcript -Path "$LogPath\DiskCleanupLogs_$Timestamp-Detection.txt"
[System.DateTime]::Now
Write-Host ""

#Check free disk space on the OS drive (C:)
Try {
    $RawFreeSpace = (Get-WmiObject Win32_logicaldisk -ErrorAction Stop | Where-Object { $_.DeviceID -eq 'C:' }).freespace
    $FreeSpaceGB = [decimal]("{0:N2}" -f($RawFreeSpace / 1GB))
    Write-Host "Current Free Space on the OS Drive : $FreeSpaceGB GB" -ForegroundColor Magenta
} Catch {
    $FreeSpaceGB = $false
    Write-Host "Unable to retrieve free space from OS drive." -ForegroundColor Red
    }

Write-Host "*******************************************************************************************"
If ($FreeSpaceGB -le $MinimumAvailableSpace) {
    Write-Host "Free space is less than $MinimumAvailableSpace GB. Proceeding to disk cleanup script." -ForegroundColor Red
    Write-Host "*******************************************************************************************"
    Stop-Transcript
    exit 1
}
else {
    Write-Host "Free space is greater than $MinimumAvailableSpace GB. No action required." -ForegroundColor Green
    Write-Host "*******************************************************************************************"
    Stop-Transcript
    exit 0
}
