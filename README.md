

## **Bicep Naming-Module POC** - An approach to handle consistent naming in Bicep-Modules


#### I haven't foud anything else good for naming in Bicep yet and Microsoft just always seems to use vars and implement Naming in every Module. So sharing this one here for a centralised solution. Hope it helps anyone else 🚀😊

<br>

This approach for a naming-module uses:
- [User Defined Functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions)
- [Import and Export](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-import)

<br>

> <span style="color:orange">**Since `User Defined Functions` were release with Bicep 0.26.x, this Approach requires Bicep 0.26.x or higher**</span>

> <span style="color:orange">**In some previous version it can be activated as an experimental feature**</span>


<br>

## How To Use


### Defining the Naming-Module

The Naming Module consists of two Resources, which can be imported by other modules:
- `nameGenerator()`: A user defined function for generating the desired name
- `namingSchemaReference`: A reference for defining names for each resources, which is provided to the **nameGenerator()** upon calling it.


The **namingSchemaReference** consists of two parts:
- Defining the shortnames for each azure location used
- Defining the naming patterns for each azure resource used

This can be customized and extended to the desired Naming-Preferences

One or multiple SchemaReferences can be created for different Naming-Conventions. The schema is passed to the **nameGenerator()-Function**, using the information to generate an appropriate name.

```Bicep
var namingSchemaReference = {
  locations: {
    'West Europe': 'euwe'
    westeurope: 'euwe'
  }

  resources: {
    'Microsoft.KeyVault/vaults': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['kv', '<PREFIX>', '<NAME>', '<ENVIRONMENT>', '<UNIQUE_STRING>']
      required: [
        'NAME'
        'ENVIRONMENT'
      ]
    }
}
```

### Using the Naming-Module

To use the Naming-Module, the exported **schemaReference** and **nameGenerator()**-Function need to be imported. The imported **nameGenerator()**-Function can then be simply called to create the desired name.


> <span style="color:orange">**Optimally it is imported from some central place, such as a Bicep-Module-Registry, so the naming is maintend and used from one central source**</span>

> <span style="color:orange">**The Module forces an error failing the Function-Call, when a parameter defined as required in the **namingSchemaReference** is not provided!**</span>

```Bicep

// This can also be imported from a Bicep-Module-Registry
// import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.io/bicep/module.naming:1.0.0'

import { namingSchemaReference, nameGenerator } from 'module.naming.bicep'

/*

Call the nameGenerator() with:
- The resourceType as defined in the nameSchemaReference
- The nameSchmaReference (Naming-Convention) that should be used
- The parameters for generating the name
*/

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {

  // Will now generate a name such as: vnet-demo-euwe-dev-001
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
    // Define properties for the Virtual Network.
  }
}

```

<br>


## Some Advantages

### Naming maintained at one place

This approach ensures that one or multple Naming-Conventions are maintained in one central Naming-Module, that can be used and implemented by any other Module.

### Consistent Naming accross Modules

Since Naming is implemented in one central Naming-Module and not different Modules, consistent naming is ensured by every Module implementing it.

### Easy to use and implement

It is simple to implement in any module with just adding the Import-Statement and the Function-Calls.