# Deploy a Windows VM and execute a custom PowerShell script.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSupraconductor%2Fmyazuretemplates%2Fmaster%2Fdsjds%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FSupraconductor%2Fmyazuretemplates%2Fmaster%2Fdsjds%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

Based on the 101-simple-windows-vm template, this template allows you to deploy a simple Windows VM and execute a custom PowerShell script using the custom script extension. The PowerShell script installs a file on the VM.  The script and file must be staged in Azure storage and that can be done automatically using the deployment scripts in the root of this repo.

