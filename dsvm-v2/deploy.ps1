param(
 [Parameter(Mandatory=$True, HelpMessage="Nom du groupe de ressources pour la VM")]
 [string]
 $vmResourceGroupName
 )

$templateFilePath = "template.json"
$parametersFilePath = "parameters.json"

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $vmResourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    New-AzureRmResourceGroup -Name $vmResourceGroupName -Location "Canada East" -Tag @{Name="groupe";Value=$groupTag}
}
else
{
    Write-Host "Using existing resource group '$vmResourceGroupName'";
}

$results = New-AzureRmResourceGroupDeployment -ResourceGroupName $vmResourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose;
$results;



