targetScope = 'managementGroup'

param environment string = 'dev'

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

// Import schema and function from Naming-Module
// import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.io/module.naming:1.0.0'
import { namingSchemaReference, nameGenerator } from '../modules/module.naming.bicep'

// Use 'nameGenerator()'-Function for consistent naming.
output subscriptionNamingExample string = nameGenerator(
  'Microsoft.Subscription/alias',
  namingSchemaReference,
  {
    company: 'adesso'
    name: 'demo'
    environment: environment
    identifier: 1234
  }
)
