$TypeDef = @"
 
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
 
namespace Api
{
 public class Kernel32
 {
   [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
   public static extern int OOBEComplete(ref int bIsOOBEComplete);
 }
}
"@
 
Add-Type -TypeDefinition $TypeDef -Language CSharp
$IsOOBEComplete = $False
$hr = [Api.Kernel32]::OOBEComplete([ref] $IsOOBEComplete)
 
If ($IsOOBEComplete) {
return $True 
}
else {
return $False 
}