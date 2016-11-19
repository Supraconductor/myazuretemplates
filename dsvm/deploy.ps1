<#
    .DESCRIPTION
        An example runbook which gets all the ARM resources using the Run As Account (Service Principal)

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Mar 14, 2016
#>
param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [string]
 $resourceGroupLocation = "eastus2",

 [string]
 $CommonResourceGroupName = "sndbx-comm-rg",

 [Parameter(Mandatory=$True)]
 [PSCredential]
 $adminCredential,

 [Parameter(Mandatory=$True)]
 [string]
 $sandboxName,

 [Parameter(Mandatory=$True)]
 [string]
 $groupName,

 [string]
 $subnetName = "sndbx",

 [string]
 $virtualNetworkName = "sndbx-comm-vnet",
 
 [string]
 $virtualMachineSize = "Standard_DS3_v2"

)

#$templateFilePath = "https://raw.githubusercontent.com/Supraconductor/myazuretemplates/master/dsvm/template.json"
#blob avec politique acces container
$templateFilePath = "https://sndbxcomtempl.blob.core.windows.net/templates/template.json"

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

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -Tag @{Name="groupe";Value=$groupName}
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

$params = @{adminPassword=$adminCredential.GetNetworkCredential().Password;GroupeDeTravail=$groupName;SandboxName=$sandboxName;adminUsername=$adminCredential.UserName;CommonResourceGroupName=$CommonResourceGroupName;subnetName=$subnetName;virtualNetworkName=$virtualNetworkName;virtualMachineSize=$virtualMachineSize}

$results = New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterObject $params;
$results;

# create a context for account and key
$ctx = New-AzureStorageContext $results.Outputs.sharedStorageAccountName.Value $results.Outputs.key.Value
$s = New-AzureStorageShare partage -Context $ctx




