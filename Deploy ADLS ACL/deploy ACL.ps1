<#
.SYNOPSIS
Recursively sets permissions on a Data Lake Store filesystem, at the specified path.

.DESCRIPTION
Recursively sets permissions on a Data Lake Store filesystem, 
at the specified path, for either (1) a given "User" or service 
principal, (2) a given "Group", or (3) "Other".

.PARAMETER DLSAccountName
The name of the Data Lake Store account to which to add or remove the user, group or other permission.

.PARAMETER EntityIdToAdd
The Azure AD Object ID of the user or group to add. This should not be specified for 'other' permissions.
The recommendation to ensure the right user or group is added is to run Get-AzureRMAdUser or 
Get-AzureRMAdGroup and pass in the Object ID returned by that cmdlet.

Yves, you can use https://graphexplorer2.cloudapp.net to find Object ID 
https://graphexplorer2.cloudapp.net ... /groups/your group name
https://graphexplorer2.cloudapp.net ... /users/email

.PARAMETER EntityType -> "User" or "Group"
Indicates if the entity to be added is a User, Group or the other permission.

.PARAMETER Path -> Starting with /
The path to start giving the specified entity permissions. This will also recursively propagate those permissions.

.PARAMETER Permissions -> "All", "ReadExecute", or "None"
The permissions to give the user, group or other. This can be "All", "ReadExecute", or "None".

#>
param
(
    [Parameter(Mandatory=$false)]
    [string] $DLSAccountName,

    [Parameter(Mandatory=$false)]
    [string] $EntityToAdd,

    [ValidateSet("User", "Group", "Other")]
    [Parameter(Mandatory=$true)]
    [string] $EntityType,

    [Parameter(Mandatory=$true)]
    [string] $Path,

    [ValidateSet("All", "ReadExecute", "None")]
    [Parameter(Mandatory=$true)]
    [string] $Permissions
)


$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

function giveaccess
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $Account,
        [Parameter(Mandatory=$true)]
        [string] $Path,
        [Parameter(Mandatory=$false)]
        [string] $IdToAdd,
        [Parameter(Mandatory=$true)]
        [string] $entityType,
        [Parameter(Mandatory=$true)]
        [string] $permissionToAdd,
        [Parameter(Mandatory=$false)]
        [switch] $isDefault = $false,
        [Parameter(Mandatory=$true)]
        [string] $loginProfilePath
    )
    
    # There is not an easy way to check if the user is part of an existing security group with permissions, so we are going to need to just add the ACE

    $aceToAdd = "$entityType`:$idToAdd`:$permissionToAdd"
    if($isDefault)
    {
        $aceToAdd = @("default:$aceToAdd","$aceToAdd")
    }
    
    Select-AzureRMProfile -Path $loginProfilePath | Out-Null
    Set-AzureRmDataLakeStoreItemAclEntry -Account $Account -Path $Path -Acl $aceToAdd
}

function copyacls
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $Account,
        [Parameter(Mandatory=$true)]
        [string] $Path,
        [Parameter(Mandatory=$true)]
        [string] $Permissions,
        [Parameter(Mandatory=$false)]
        [string] $IdToAdd,
        [Parameter(Mandatory=$true)]
        [string] $entityType,
        [Parameter(Mandatory=$true)]
        [string] $loginProfilePath
    )
    
    $itemList = Get-AzureRMDataLakeStoreChildItem -Account $Account -Path $Path;
    foreach($item in $itemList)
    {
        $pathToSet = Join-Path -Path $Path -ChildPath $item.PathSuffix;
        $pathToSet = $pathToSet.Replace("\", "/");
        
        if ($Permissions -ieq "All")
        {
            $perms = "rwx";
        }
        elseif ($Permissions -ieq "ReadExecute")
        {
            $perms = "r-x";
        }
        else
        {
            $perms = "---";
        }
        
        if ($item.Type -ieq "FILE")
        {
            # set the ACL without default
            giveaccess -Account $Account -Path $pathToSet -IdToAdd $IdToAdd -entityType $entityType -permissionToAdd $perms -loginProfilePath $loginProfilePath | Out-Null
        }
        elseif ($item.Type -ieq "DIRECTORY")
        {
            # set permission and recurse on the directory
            giveaccess -Account $Account -Path $pathToSet -IdToAdd $IdToAdd -entityType $entityType -permissionToAdd $perms -isDefault -loginProfilePath $loginProfilePath | Out-Null
            copyacls -Account $Account -Path $pathToSet -Permissions $Permissions -IdToAdd $IdToAdd -entityType $entityType -loginProfilePath $loginProfilePath | Out-Null
        }
        else
        {
            throw "Invalid path type of: $($item.Type). Valid types are 'DIRECTORY' and 'FILE'"
        }
    }
}

# This script assumes the following:
# 1. The Azure PowerShell environment is installed
# 2. The current session has already run "Login-AzureRMAccount" with a user account that has permissions to the specified ADLS account
try
{   if($EntityType -ieq "other" -and !([string]::IsNullOrEmpty($EntityToAdd)))
	{
		throw "EntityToAdd is not supported when modifying permissions for 'Other' entity types"
	}
	
	if($EntityType -ine "other" -and [string]::IsNullOrEmpty($EntityToAdd))
	{
		throw "EntityToAdd is required when modifying permissions for 'user' and 'group' entity types"
	}

    $objectId = $EntityToAdd
    	
	$ignored = [Guid]::Empty
	if($EntityType -ine "other" -and !([Guid]::TryParse($objectId, [ref]$ignored)))
	{
		throw "EntityToAdd can't get a object ID. EntityToAdd value was: $EmailOrGroupName"
	}
    
    $profilePath = Join-Path $env:TEMP "jobprofilesession.tmp"
    if(Test-Path $profilePath)
    {
        Remove-Item $profilePath -Force -Confirm:$false
    }
    
    Save-AzureRMProfile -path $profilePath | Out-Null
    
    Write-Host "Request to add entity: $objectId successfully submitted and will propagate over time depending on the size of the folder."
    Write-Host "Please do not close this PowerShell window; otherwise, the propagation will be cancelled."
    if($EntityType -ieq "other")
    {
        Set-AzureRmDataLakeStoreItemAclEntry -Account $DLSAccountName -Path $Path -AceType $EntityType -Permissions $Permissions
        Set-AzureRmDataLakeStoreItemAclEntry -Account $DLSAccountName -Path $Path -AceType $EntityType -Permissions $Permissions
    }
    else
    {
        Set-AzureRmDataLakeStoreItemAclEntry -Account $DLSAccountName -Path $Path -AceType $EntityType -Id $objectId -Permissions $Permissions
        Set-AzureRmDataLakeStoreItemAclEntry -Account $DLSAccountName -Path $Path -AceType $EntityType -Id $objectId -Permissions $Permissions -Default
    }
    copyacls -Account $DLSAccountName -Path $Path -Permissions $Permissions -IdToAdd $objectId -entityType $EntityType -loginProfilePath $profilePath | Out-Null
}
catch
{
    Write-Error "ACL propagation failed with the following error: $($error[0])"
}

