
# Connect to Microsoft Graph
# Connect-MgGraph -Scopes "User.ReadWrite.All"

# Import CSV file containing user data
$users = Import-Csv "C:\temp\EIEntraEmployeeDetailsUpdate - fixed.csv"

# Define combined log file path
$combinedLog = "C:\temp\EIUserUpdateLog.csv"

foreach ($user in $users) {
    try {
        # Clear Variables from last run
        $prechange = @()
        $postchange = @()
        $logentry = @()

        # Set empty values to $null
        if ([string]::IsNullOrEmpty($user.CompanyName)){
            $user.CompanyName = $null
        }
        if ([string]::IsNullOrEmpty($user.employeeId)){
            $user.employeeId = $null
        }
        if ([string]::IsNullOrEmpty($user.JobTitle)){
            $user.JobTitle = $null
        }

        # Get current/pre change user details and store as a variable
        $prechange = Get-MgUser -UserId $user.UPN -Property "Id,CompanyName,EmployeeId,JobTitle" -ErrorAction Stop

        # Attempt to update user info (even if empty)
        # Update-MgUser -UserId $user.UPN -CompanyName $user.CompanyName -EmployeeId $user.EmployeeId -JobTitle $user.JobTitle -ErrorAction Stop
        $userId = $prechange.Id
        $uri = "https://graph.microsoft.com/v1.0/users/$userId"
        $body = @{
            "CompanyName" = $user.CompanyName
            "EmployeeId" = $user.EmployeeId
            "JobTitle" = $user.JobTitle
        } | ConvertTo-Json

        Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $body -ContentType "application/json" -ErrorAction Stop

        # Get new/post change user details and store as a variable
        $postchange = Get-MgUser -UserId $user.UPN -Property "UserPrincipalName,CompanyName,EmployeeId,JobTitle" -ErrorAction Stop


        # Log successful update with old and new
        $logEntry = [PSCustomObject]@{
            Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            User = $user.UPN
            Status = "SUCCESS"
            oldCompanyName = $prechange.CompanyName
            newCompanyName = $postchange.CompanyName
            OldEmployeeId = $prechange.EmployeeId
            newEmployeeId = $postchange.EmployeeId
            oldJobTitle = $prechange.JobTitle
            newJobTitle = $postchange.JobTitle
            Message = "User details updated successfully"
        }
        $LogEntry | Export-Csv -Path $combinedLog -NoTypeInformation -Append
        Write-Host "User details for $($user.UPN) updated successfully" -ForegroundColor green
    }
    catch {
        # Log error details from exception, including old and intended new title
        $logEntry = [PSCustomObject]@{
            Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            User = $user.UPN
            Status = "ERROR"
            oldCompanyName = $prechange.CompanyName
            newCompanyName = $postchange.CompanyName
            OldEmployeeId = $prechange.EmployeeId
            newEmployeeId = $postchange.EmployeeId
            oldJobTitle = $prechange.JobTitle
            newJobTitle = $postchange.JobTitle
            Message = ($_.Exception.Message -replace "`r?`n"," " -replace ","," ")

        }
        $LogEntry | Export-Csv -Path $combinedLog -NoTypeInformation -Append
        Write-Host "Failed to update $($user.UPN): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Disconnect session
# Disconnect-MgGraph