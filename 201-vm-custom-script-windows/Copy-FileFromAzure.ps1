param (
    [string]$pass
)
$securepassword = ConvertTo-SecureString -string $pass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PsCredential('blobanalyticsgtd',$securepassword)
New-PSDrive -Name "S" -Scope Global -PSProvider FileSystem -Root "\\blobanalyticsgtd.file.core.windows.net\dsvmshare" -Persist -Credential $cred
