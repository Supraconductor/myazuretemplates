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
 $CommonResourceGroupName = "adlsandboxcmn",
 
 # utiliser InitialVMCredential - ne peut pas être par défaut
 [Parameter(Mandatory=$True)]
 [PSCredential]
 $adminCredential,

 [Parameter(Mandatory=$True)]
 [string]
 $sandboxNameMax8Char,

 [Parameter(Mandatory=$True)]
 [string]
 $groupNameForTag,

 [string]
 $CommonSubnetName = "default",

 [string]
 $CommonVirtualNetworkName = "adlsandboxcmn",
 
 [string]
 $virtualMachineSize = "Standard_DS3_v2"

)

#blob avec politique acces container
$templateFilePath = "https://adlsandboxcmnstorage.blob.core.windows.net/templates/template.json"

#connection à utiliser pour se connecter à Azure avec un service principal pour exécuter le runbook
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
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -Tag @{Name="groupe";Value=$groupNameForTag}
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

#contruction des paramètres pour l'appel au gabarit
$params = @{adminPassword=$adminCredential.GetNetworkCredential().Password;GroupeDeTravail=$groupNameForTag;SandboxName=$sandboxNameMax8Char;adminUsername=$adminCredential.UserName;CommonResourceGroupName=$CommonResourceGroupName;subnetName=$CommonSubnetName;virtualNetworkName=$CommonVirtualNetworkName;virtualMachineSize=$virtualMachineSize}

#déployement du gabarit avec les paramètres
$results = New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterObject $params;
$results;

# create a context for account and key
# pour créer un nouveau Azure Files Share
$ctx = New-AzureStorageContext $results.Outputs.sharedStorageAccountName.Value $results.Outputs.key.Value
$s = New-AzureStorageShare partage -Context $ctx




