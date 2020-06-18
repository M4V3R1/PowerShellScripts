If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))

{
$arguments = "& '" + $myinvocation.mycommand.definition + "'"
Start-Process powershell -Verb runAs -ArgumentList $arguments
Break
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
Write-Host NETWORK COPY SCRIPT - CREATED BY JAMES HURLING 2020
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

Remove-Item A: -Force -Recurse

net use A: /delete
net use B: /delete

Write-Host "Temporary Drives have been removed..."
Stop-Transcript
Pause