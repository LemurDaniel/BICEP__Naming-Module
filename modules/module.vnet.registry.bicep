/*

  Import schema and function from Naming-Module.

  This imports the Naming-Module from a versioned Bicep-Module Registry

*/

import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.io/bicep/module.naming:1.0.0'

/*

  Define module parameters

*/

param location string = resourceGroup().location
param environment string

param vnetConfig {
  name: string
  addressPrefix: string[]
  subnets: string[]
}

/*

  Define module resources and use the imported 'nameGenerator()'-Function for consistent naming in all modules.

*/

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: nameGenerator(
    'Microsoft.Network/virtualNetworks',
    namingSchemaReference,
    {
      name: vnetConfig.name
      location: location
      environment: environment
      postfixIndex: 1
    }
  )
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: vnetConfig.addressPrefix
    }
    subnets: [
      for (subnetCidr, index) in vnetConfig.subnets: {
        name: nameGenerator(
          'Microsoft.Network/virtualNetworks/subnets',
          namingSchemaReference,
          {
            name: vnetConfig.name
            location: location
            environment: environment
            postfixIndex: index + 1
          }
        )

        properties: {
          addressPrefix: subnetCidr
        }
      }
    ]
  }
}

output virutalNetworkName string = virtualNetwork.name
output subnetNames string[] = map(virtualNetwork.properties.subnets, snet => snet.name)
