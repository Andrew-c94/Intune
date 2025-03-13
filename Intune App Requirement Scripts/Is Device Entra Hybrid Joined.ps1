$tenantID = $null
if (Test-Path "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo") {
    $subKey = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
    $guids = $subKey.GetSubKeyNames()
    foreach($guid in $guids) {
        $guidSubKey = $subKey.OpenSubKey($guid);
        $tenantId = $guidSubKey.GetValue("TenantId");
    }
}
if ($null -ne $tenantID) {
return $True
} 
else {
return $False
}