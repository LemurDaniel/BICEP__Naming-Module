targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'dev'

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

import { defaultSchema } from '../../modules/naming-schema/module.bicep'
import { name, nameKind } from '../../modules/naming/module.bicep'

output dataDiskNamingExample string = nameKind('Microsoft.Compute/disks', 'data', defaultSchema, {
  name: 'apps'
  location: location
  environment: environment
  index: 12 // Error by being out of range
})
output osDiskNamingExample string = nameKind('Microsoft.Compute/disks', 'data', defaultSchema, {
  name: 'apps'
  location: location
  environment: environment
  index: 1
})
