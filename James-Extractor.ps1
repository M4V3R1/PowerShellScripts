If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))

{   
$arguments = "& '" + $myinvocation.mycommand.definition + "'"
Start-Process powershell -Verb runAs -ArgumentList $arguments
Break
}

Function Format-FileSize() {
Param ([int]$size)
If ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
ElseIf ($size -gt 0) {[string]::Format("{0:0.00} B", $size)}
Else {""}
}

<#
.NOTES
===========================================================================
Created on: 16/06/2020 05:24
Created by: James Hurling
Organization:
===========================================================================
.DESCRIPTION
Network user profile data mover/extractor ...#>
Start-Transcript -path c:\TEMP\transcript.txt -Append -Force -IncludeInvocationHeader
Write-Host ------------------------------------------------------------------------------------------
Write-Host         NETWORK COPY SCRIPT - CREATED BY JAMES HURLING 2020
Write-Host ------------------------------------------------------------------------------------------

Import-Module ActiveDirectory
$user = Read-Host -Prompt 'Username required for Move'
$homedirectory = Get-AdUser -filter {name -eq $user} -properties * | ForEach-Object {$_.HomeDirectory}
$ADrive = "$homedirectory"
$BDrive = "\\ourfilesdc\PRH-Archive\PRH_Homedrive_archive"

$Admin = [Environment]::UserName
Write-Host "Current Logged in Administrator: '$Admin'"

$rule = new-object System.Security.AccessControl.FileSystemAccessRule ("$Admin","FullControl","Allow")
$acl = Get-ACL "$HomeDirectory"
$acl.SetAccessRule($rule)
Set-ACL -Path "$HomeDirectory" -AclObject $acl

function Grant-userFullRights {            
 [cmdletbinding()]            
 param(            
 [Parameter(Mandatory=$true)]            
 [string[]]$Files,            
 [Parameter(Mandatory=$true)]            
 [string]$Admin           
 )            
 $rule=new-object System.Security.AccessControl.FileSystemAccessRule ($Admin,"FullControl","Allow")            

 foreach($File in $Files) {            
  if(Test-Path $File) {            
   try {            
    $acl = Get-ACL -Path $File -ErrorAction stop            
    $acl.SetAccessRule($rule)            
    Set-ACL -Path $File -ACLObject $acl -ErrorAction stop            
    Write-Host "Successfully set permissions on $File"            
   } catch {            
    Write-Warning "$File : Failed to set perms. Details : $_"            
    Continue            
   }            
  } else {            
   Write-Warning "$File : No such file found"            
   Continue            
  }            
 }            
}

Write-Host "Selected Username: '$user'"

Write-Host "Home Directory Location: '$homedirectory'"

Write-Host "Drive A has been mapped to '$ADrive'"

net use A: $ADrive
Write-Host "Drive B has been mapped to '$BDrive'"

net use B: $BDrive

Compress-Archive -Path $homedirectory\* -CompressionLevel Optimal -DestinationPath \\ourfilesdc\PRH-Archive\PRH_Homedrive_archive".zip" -Force

$file = $ADrive
$size=Format-FileSize((Get-Item $file).length)
Write-Host "Home Directory: " ($size)

$file = $BDrive
$size=Format-FileSize((Get-Item $file).length)
Write-Host "Zipped File: " ($size)

Remove-Item A: -Force -Recurse

if(!(Test-Path -Path $homedirectory)){

Write-Host "!! REMOVAL COMPLETED, User Files & Folders within '$ADrive' have been removed... !!" -ForegroundColor Green

}
else
{
  Write-Host "!! REMOVAL FAILED, User Files & Folders within '$ADrive' have NOT been removed... !!" -ForegroundColor Red
	Write-Host "Please Check this directory for missing Files/Folders within the Zip Backup!" -ForegroundColor Red
}

net use A: /delete
net use B: /delete

Write-Host "Temporary Drives have been removed..."
Stop-Transcript
Pause