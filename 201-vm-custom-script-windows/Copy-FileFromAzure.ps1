param (
    [System.Security.SecureString]$pass
)

$cred = New-Object System.Management.Automation.PsCredential('blobanalyticsgtd',$pass)
New-PSDrive -Name "S" -Scope Global -PSProvider FileSystem -Root "\\blobanalyticsgtd.file.core.windows.net\dsvmshare" -Persist -Credential $cred
