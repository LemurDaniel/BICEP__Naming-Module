targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'dev'

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

// Import schema and function from Naming-Module
// import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.io/module.naming:1.0.0'
import { namingSchemaReference, nameGenerator } from '../modules/module.naming.bicep'

output functionAppNamingExample string = nameGenerator(
  'Microsoft.Web/sites/functions',
  namingSchemaReference,
  {
    name: 'apps'
    location: location
    environment: environment
    postfixIndex: 1222 // Error by being out of range
  }
)
output dataDiskNamingExample string = nameGenerator(
  'Microsoft.Compute/disks',
  namingSchemaReference,
  {
    name: 'apps'
    location: location
    environment: environment
    diskType: 'datadisk'
    diskLun: 12 // Error by being out of range
  }
)
output osDiskNamingExample string = nameGenerator(
  'Microsoft.Compute/disks',
  namingSchemaReference,
  {
    name: 'apps'
    location: location
    environment: environment
    diskType: 'blabla' // Error by not being in allowed value set
    diskLun: 1
  }
)
