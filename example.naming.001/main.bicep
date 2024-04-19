targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'dev'

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

// Import schema and function from Naming-Module
import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.io/bicep/module.naming:1.0.0'
// import { namingSchemaReference, nameGenerator } from './modules/module.naming.bicep'

// Use 'nameGenerator()'-Function for consistent naming.
output kvNamingExample string = nameGenerator(
  'Microsoft.KeyVault/vaults',
  namingSchemaReference,
  {
    name: 'secrets'
    location: location
    environment: environment
  }
)
output storageAccountNamingExample string = nameGenerator(
  'Microsoft.Storage/storageAccounts',
  namingSchemaReference,
  {
    name: 'objects'
    location: location
    environment: environment
  }
)
