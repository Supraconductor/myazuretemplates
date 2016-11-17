param (
    [string]$pass
)
$securepassword = ConvertTo-SecureString -string $pass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PsCredential('blobanalyticsgtd',$securepassword)
<# New-PSDrive -Name "S" -Scope Global -PSProvider FileSystem -Root "\\blobanalyticsgtd.file.core.windows.net\dsvmshare" -Persist -Credential $cred
cmdkey /add:blobanalyticsgtd.file.core.windows.net /user:blobanalyticsgtd /pass:$pass #>
New-Item 'C:\Users\default\Desktop\mapdrive.cmd' -type file -force 
Set-Content 'C:\Users\default\Desktop\mapdrive.cmd' "net use s: \\blobanalyticsgtd.file.core.windows.net\dsvmshare /u:blobanalyticsgtd $pass"