#Minimum free disk space (GB)
$MinimumAvailableSpace = 35

#Check free disk space on the OS drive (C:)
Try {
    $RawFreeSpace = (Get-WmiObject Win32_logicaldisk -ErrorAction Stop | Where-Object { $_.DeviceID -eq 'C:' }).freespace
    $FreeSpaceGB = [decimal]("{0:N2}" -f($RawFreeSpace / 1GB))
    Write-Host "Current Free Space on the OS Drive : $FreeSpaceGB GB" -ForegroundColor Magenta
} Catch {
    $FreeSpaceGB = $false
    Write-Host "Unable to retrieve free space from OS drive." -ForegroundColor Red
    }

If ($FreeSpaceGB -le $MinimumAvailableSpace) {
    Write-Host "Free space is less than $MinimumAvailableSpace GB. Proceeding to disk cleanup script." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "Free space is greater than $MinimumAvailableSpace GB. No action required." -ForegroundColor Green
    exit 0
}