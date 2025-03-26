$dcInfo = [ADSI]"LDAP://RootDSE"

If ($null -ne $dcInfo.dnsHostName){
return $True
}
else {
return $False
}