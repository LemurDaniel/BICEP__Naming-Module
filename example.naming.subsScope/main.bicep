targetScope = 'subscription'

param environment string = 'dev'
param location string = deployment().location

/*

  NOTE: Requires Version 0.26.x or higher
  https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions

*/

// Import schema and function from Naming-Module
// import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.io/module.naming:1.0.0'
import { namingSchemaReference, nameGenerator } from '../modules/module.naming.bicep'

// Use 'nameGenerator()'-Function for consistent naming.
output resoureGroupNamingExample string[] = [
  for index in range(0, 3): nameGenerator(
    'Microsoft.Resources/resourceGroups',
    namingSchemaReference,
    {
      name: 'demo'
      environment: environment
      location: location
      postfixIndex: index
    }
  )
]
