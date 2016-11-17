<# Custom Script for Windows to install a file from Azure Storage using the staging folder created by the deployment script #>
param (
    [string]$pass
)

$cred = New-Object System.Management.Automation.PsCredential('blobanalyticsgtd',$pass)
New-PSDrive –Name "S" –PSProvider FileSystem –Root "\\blobanalyticsgtd.file.core.windows.net\dsvmshare" –Persist 
