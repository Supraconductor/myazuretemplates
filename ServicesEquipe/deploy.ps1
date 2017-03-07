param(
 [Parameter(Mandatory=$True, HelpMessage="Nom du groupe de ressources pour les services communs")]
 [string]
 $commonTeamResourceGroupName, 
 [Parameter(Mandatory=$True, HelpMessage="Valeur du tag: group")]
 [string]
 $groupTag
)

$templateFilePath = "template.json"
$parametersFilePath = "parameters.json"
#JF
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

$results = New-AzureRmResourceGroupDeployment -ResourceGroupName $commonTeamResourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose;
$results;

$ctx = New-AzureStorageContext $results.Outputs.sharedStorage.Value $results.Outputs.key.Value
$s = New-AzureStorageShare partage -Context $ctx




