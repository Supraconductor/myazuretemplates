param(
 [Parameter(Mandatory=$True, HelpMessage="Nom du group global avec le vNet")]
 [string]
 $commonGlobalResourceGroupName,
 [Parameter(Mandatory=$True, HelpMessage="Nom du groupe de ressources pour les services communsde l'équipe'")]
 [string]
 $commonTeamResourceGroupName, 
 [Parameter(Mandatory=$True, HelpMessage="Valeur du tag: group")]
 [string]
 $groupTag,
 [Parameter(Mandatory=$True, HelpMessage="Nom du vNet")]
 [string]
 $commonVNetName,
 [Parameter(Mandatory=$True, HelpMessage="Nom du subnet à créer")]
 [string]
 $subnetName,
 [Parameter(Mandatory=$True, HelpMessage="IP range du nouveau subnet (ex:10.1.0.8/29)")]
 [string]
 $subnetIpRange
)

$templateFilePath = "template.json"
$parametersFilePath = "parameters.json"

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $commonTeamResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    New-AzureRmResourceGroup -Name $commonTeamResourceGroupName -Location "Canada East" -Tag @{Name="groupe";Value=$groupTag}
}
else
{
    Write-Host "Using existing resource group '$commonTeamResourceGroupName'";
}

#Ajouter meilleure gestion des erreurs et exceptions...
$vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName $commonGlobalResourceGroupName -Name $commonVNetName
Add-AzureRmVirtualNetworkSubnetConfig -Name $commonTeamResourceGroupName -VirtualNetwork $vnet2 -AddressPrefix $subnetIpRange
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet2

$results = New-AzureRmResourceGroupDeployment -ResourceGroupName $commonTeamResourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose;
$results;

$ctx = New-AzureStorageContext $results.Outputs.sharedStorage.Value $results.Outputs.key.Value
$s = New-AzureStorageShare partage -Context $ctx




