targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string
param virtualNetwork {
  name: string
  addressPrefix: string[]
  subnets: string[]
}

/*

  Call module with integrated naming

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions
*/

module vnetModule '../modules/module.vnet.local.bicep' = {
  name: 'module.vnet.${environment}'
  params: {
    location: location
    environment: environment
    vnetConfig: virtualNetwork
  }
}

output vnetName string = vnetModule.outputs.virutalNetworkName
output subnetNames string[] = vnetModule.outputs.subnetNames
