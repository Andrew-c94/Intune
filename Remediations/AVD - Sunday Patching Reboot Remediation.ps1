$taskName = "Sunday Patching Reboot (If Required)"

$psCommand = "if ((New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search('IsInstalled=0').Updates.Count -gt 0) { shutdown.exe /r /t 300 /c 'This server will restart in 5 minutes to install important updates. Please save your work.' }"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"$psCommand`""

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "20:00"

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

$settings = New-ScheduledTaskSettingsSet -Compatibility Win8

$task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings

Register-ScheduledTask -TaskName $taskName -InputObject $task -Force