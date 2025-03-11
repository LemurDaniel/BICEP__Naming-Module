targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'dev'

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

import { defaultSchema } from '../../modules/naming-schema/module.bicep'
import { name, nameKind } from '../../modules/naming/module.bicep'

// Use 'nameGenerator()'-Function for consistent naming.
output kvNamingExample string = name('Microsoft.KeyVault/vaults', defaultSchema, {
  name: 'secrets'
  location: location
  environment: environment
})
output storageAccountNamingExample string = name('Microsoft.Storage/storageAccounts', defaultSchema, {
  name: 'objects'
  location: location
  environment: environment
})
output functionAppNamingExample string = nameKind('Microsoft.Web/sites', 'functionApp', defaultSchema, {
  name: 'apps'
  location: location
  environment: environment
  index: 1
})
output dataDiskNamingExample string = nameKind('Microsoft.Compute/disks', 'data', defaultSchema, {
  name: 'apps'
  location: location
  environment: environment
  index: 1
})
output osDiskNamingExample string = nameKind('Microsoft.Compute/disks', 'os', defaultSchema, {
  name: 'apps'
  location: location
  environment: environment
  index: 1
})
