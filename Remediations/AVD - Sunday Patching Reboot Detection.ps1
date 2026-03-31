$taskName = "Sunday Patching Reboot (If Required)"

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    if ($task) {
        Write-Host "Task exists."
        exit 0
    }
} catch {
    Write-Host "Task does not exist."
    exit 1
}