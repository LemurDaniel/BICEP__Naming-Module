


$resourceGroup = "rg-bicepnamingpoc-test-001"
$location = "westeurope"

New-AzResourceGroup -Name $resourceGroup -Location $location

<#

$moduleRegistry = "bicepnamingpoc001"
New-AzContainerRegistry `
      -Name $moduleRegistry `
      -ResourceGroupName $resourceGroup `
      -Location $location `
      -Sku "Basic"


# Publis the Naming-Module in a registry for reuse across all module.
Publish-AzBicepModule `
      -FilePath "./modules/module.naming.bicep" `
      -Target "br:$moduleRegistry.azurecr.io/module.naming:1.0.0"

#>


#############################################################
#
# Deploy bicep file for naming examples

$Deployment = @{
      Name              = "pwsh.example.naming.001"
      TemplateFile      = "./example.naming.001/main.bicep"
      ResourceGroupName = $resourceGroup
}
      
New-AzResourceGroupDeployment @Deployment


#############################################################
#
# Deploy bicep file for naming error examples

$Deployment = @{
      Name              = "pwsh.example.naming.errors"
      TemplateFile      = "./example.naming.errors/main.bicep"
      ResourceGroupName = $resourceGroup
}
      
New-AzResourceGroupDeployment @Deployment


#############################################################
#
# Deploy bicep file for vnet naming example

$Deployment = @{
      Name                  = "pwsh.example.naming.vnet"
      TemplateFile          = "./example.naming.vnet/main.bicep"
      TemplateParameterFile = "./example.naming.vnet/environments/dev.main.bicepparam"
      ResourceGroupName     = $resourceGroup
}
      
New-AzResourceGroupDeployment @Deployment


#############################################################
#
# Deploy bicep file for resource group naming example

$Deployment = @{
      Name         = "pwsh.example.naming.subsScope"
      TemplateFile = "./example.naming.subsScope/main.bicep"
      Location     = "West Europe"
}
      
New-AzSubscriptionDeployment @Deployment


#############################################################
#
# Deploy bicep file for subscription naming example

$Deployment = @{
      Name              = "pwsh.example.naming.mmgScope"
      TemplateFile      = "./example.naming.mmgScope/main.bicep"
      ManagementGroupId = (Get-AzContext).Tenant.Id
      Location          = "West Europe"
}
      
New-AzManagementGroupDeployment @Deployment