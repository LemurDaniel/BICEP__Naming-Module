targetScope = 'subscription'

param environment string = 'dev'
param location string = deployment().location

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

import { defaultSchema } from '../../modules/naming-schema/module.bicep'
import { name, nameKind } from '../../modules/naming/module.bicep'

// Use 'nameGenerator()'-Function for consistent naming.
output resoureGroupNamingExample string[] = [
  for index in range(0, 3): name('Microsoft.Resources/resourceGroups', defaultSchema, {
    name: 'demo'
    environment: environment
    location: location
    index: index
  })
]
