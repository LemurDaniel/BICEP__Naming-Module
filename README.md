## **Bicep Naming-Module POC** - An approach to handle consistent naming in Bicep-Modules

#### I haven't found anything else good for naming in Bicep yet, and Microsoft just always seems to use vars and implement naming in every module. So, sharing this one here for a centralized solution. Hope it helps anyone else! 🚀😊

This approach for a Naming-Module uses:
- [User Defined Functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions)
- [Import and Export](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-import)

<br>

```Bicep
import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.io/module.naming:1.0.0'

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

> <span style="color:orange">**Since `User Defined Functions` were released with Bicep 0.26.x, this approach requires Bicep 0.26.x or higher**</span>

> <span style="color:orange">**In some previous versions, it can be activated as an experimental feature**</span>

<br>

## How To Use

### Defining the Naming-Module

The Naming-Module consists of two resources, which can be imported by other modules:
- `nameGenerator()`: A user defined function for generating the desired name
- `namingSchemaReference`: A reference for defining names for each resource, which is provided to the **nameGenerator()** upon calling it

The **namingSchemaReference** consists of two parts:
- Defining the short names for each Azure location used
- Defining the naming patterns for each Azure resource used

This can be customized and extended to the desired Naming-Preferences. One or multiple **SchemaReferences** can be created for different Naming-Conventions. The schema is passed to the **nameGenerator()-Function**, using the information to generate an appropriate name. Each resource definition defines the naming via a pattern, delimiter and required parameters. A special formatting can be applied to certain parameters. A PostfixIndex can be formated this way to be always padded with three zeroes, turning '1' into '001'. The validation block can apply validation of a range or a set for each parameter, forcing an error on fail.

```Bicep
// NOTE: Needs to be exported, so it can be imported by other modules
@export()
var namingSchemaReference = {
  locations: {
    'West Europe': 'euwe'
    westeurope: 'euwe'
  }

  resources: {
    'Microsoft.Network/virtualNetworks': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['vnet', '<PREFIX>', '<NAME>', '<LOCATION>', '<ENVIRONMENT>', '<POSTFIX_INDEX>']
      required: [
        'NAME'
        'LOCATION'
        'ENVIRONMENT'
        'POSTFIX_INDEX'
      ]
      format: {
        // format a postfixIndex number into a string with three padded zeroes:
        // '1'  => '001'
        // '2'  => '002'
        // '12' => '012'
        POSTFIX_INDEX: '{0:000}'
      }
      validate: {
        POSTFIX_INDEX: {
          range: [0, 999]
        }
        ENVIRONMENT: {
          set: [
            'dev'
            'test'
            'prod'
          ]
        }
      }
    }
  }
}
```

### Using the Naming-Module

To use the Naming-Module, the exported **schemaReference** and **nameGenerator()**-Function need to be imported. The imported **nameGenerator()**-Function can then be simply called to create the desired name.

> <span style="color:orange">**Optimally it is imported from some central place, such as a Bicep-Module-Registry, so the naming is maintained and used from one central source**</span>

> <span style="color:orange">**The Module also forces an error failing the Function-Call when a parameter defined as required in the **namingSchemaReference** is not provided!**</span>

> <span style="color:orange">**The Module can be imported to modules with any scope**</span>

```Bicep
// This can also be imported from a Bicep-Module-Registry
// import { namingSchemaReference, nameGenerator } from 'br:bicepnamingpoc001.azurecr.iomodule.naming:1.0.0'

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

### NOTES:

The Keywords used in the pattern are customizable. For each keyword, a corresponding parameter is searched in the **parameters**-Object given on the function call. For Parameters like <CUSTOM_KEYWORD>, a camelcase parameter customKeyword is expected.

If it is required and not provided, an error such as the following is forced by the function, preventing incorrect naming to be deployed.

![example.error.missingParameter](./_resources/example.error.mssingParameter.png)

<span style="color:orange">**This doesn't apply for special Parameters which currently are UNIQUE_STRING **</span>

<span style="color:orange">**Keywords used in the pattern array need always be written in `< >`**</span>

```Bicep
resources: {
  'Microsoft.KeyVault/vaults': {
    enforceAllLowerCase: true
    delimiter: '-'

    pattern: ['kv', '<PREFIX>', '<NAME>', '<CUSTOM_PARAMETER>','<ENVIRONMENT>', '<UNIQUE_STRING>']
    required: [
      'NAME'
      'ENVIRONMENT'
      'CUSTOM_PARAMETER' 
    ]
    format: {
      CUSTOM_PARAMETER: '{0:000}'
    }
  }
}

// Upon Function-Call this now expects a custom parameter in camelcase.
var kvName = nameGenerator(
    'Microsoft.Network/virtualNetworks',
    namingSchemaReference,
    {
      name: 'secrets'
      environment: 'dev'
      customParameter: 'bla'
    }
  )

```

<br>


## Some Advantages

### Naming maintained at one place

This approach ensures that one or multiple Naming-Conventions are maintained in one central Naming-Module, that can be used and implemented by any other modules.

### Consistent naming across modules

Since Naming is implemented in one central Naming-Module and not different modules, consistent naming is ensured by every module implementing it.

### Easy to use and implement

It is simple to implement in any module with just adding the Import-Statement and the Function-Calls.



<br>


### TODOS, Ideas and stuff

- Add more naming examples and implementations for other edge-cases: