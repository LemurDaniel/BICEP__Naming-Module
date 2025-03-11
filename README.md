## **Bicep Naming-Module** - An approach to consistent naming in Bicep

#### I haven't found anything else good for naming in Bicep and Microsoft just always seems to use vars and implement naming in every module. So, sharing this one here for a centralized solution. Hope it helps anyone else! 🚀😊

This approach for a Naming-Module uses:
- [User Defined Functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-functions)
- [Import and Export](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-import)

<br>



# ⚠️ Look into [Module-Registry](https://github.com/LemurDaniel/BICEP__Module-Registry/blob/master/governance/naming/module.bicep) for a more recent Versions of this. ⚠️

---

### Following: Outdated Module:

---

```Bicep
import { defaultSchema } from './modules/naming-schema/module.bicep'
import { name, nameKind } from './modules/naming/module.bicep'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {

  // Will now generate a name such as: vnet-demo-euwe-dev-001
  name: nameGenerator('Microsoft.Network/virtualNetworks', defaultSchema,
    {
      index: 1
      name: vnetConfig.name
      location: location
      environment: environment
    }
  )

  location: location
  properties: {
    // Define properties for the Virtual Network.
  }
}
```
<br>

## How To Use

### Defining the Naming-Module

The Naming-Module consists of three resources, which can be imported by other modules:
- `name()`: Generating name for a normal resource
- `nameKind()`: Generating based on kind. FunctionApp vs. App, OSdisk vs DataDisk, etc.
- `schema`: A reference for defining names for each resource, which is provided to the **name()** upon calling it

The **namingSchemaReference**:

```Bicep

import { defaultAbbreviations } from 'var.abbr.bicep'
import { defaultLocations } from 'var.location.bicep'

@export()
var schemaReference = {
  abbreviations: defaultAbbreviations
  locations: defaultLocations

  enforceLowerCase: {
    default: true
    'Microsoft.ContainerRegistry/registries': true
    'Microsoft.Storage/storageAccounts': true
  }

  /*
    NOTE:
    - <>        : denote key words which are replaced by parameters
    - <?>       : denote a optional parameter. If not provided will be empty
    - <?;-{0}>  : optional parameter with a custom format. (Use this for optionals, because it optionally deploy the seperator '-')
    -           : everything else is treated as a string.

    SPECIAL PARAMETERS:
    The following only applies for modules, that correctly implement the naming schema.
    - <INDEX>: should always point to the current index in an iteration. (For example with multiple subnets)
    - <KEY>: should always point to the current key in an iteration. (When iterating over objects with items())
    - <LOCATION>: should always point to the location of the resource.
    - <UNIQUE_STRING_N>: is a unique id based on the resource group name. (N can be any number between 0 and 9)
  
    !!! NOTE !!!
    UNIQUE_STRING_N is only available on resource group scope, since it uses the resource group name to generate the unique string.
    The deployment name is not used, because when dealing with deployment stacks, the deployment name changes with each execution.
    This doesn't happen with normal deployments, but the module is designed to work consistently in both cases.
  */

  // This is used to modify the index.
  // Most naming start counting at 1. rg-euwe-dev-project-01
  // All modules start  with index at 1 when providing the value.
  // If you want to start at 0, you can set this to -1.
  indexModifier: 0
  patterns: {
    default: '<ABBREVIATION><?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME>'

    'Microsoft.Subscription/alias': '<COMPANY>-<NAME>-<ENVIRONMENT>-subs-<IDENTIFIER;{0:0000}>'

    // 
    'Microsoft.KeyVault/vaults': 'kv<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<UNIQUE_STRING_5>'
    'Microsoft.Storage/storageAccounts': 'st<?PREFIX><LOCATION><ENVIRONMENT><NAME>'

    // Compute
    'Microsoft.Compute/disks': {
      data: '<ABBREVIATION><INDEX;{0:00}>-<NAME>-<ENVIRONMENT>'
      OS: '<ABBREVIATION>-<NAME>-<ENVIRONMENT>'
    }
  }

  validate: {
    default: {
      INDEX: {
        range: [0, 999]
      }
    }

    // The logic checks for any type that starts with 'Microsoft.Compute/disks'
    'Microsoft.Compute/disks': {
      INDEX: {
        range: [0, 10]
      }
    }
  }
}
```


### NOTES:

The Keywords used in the pattern are customizable. For each keyword, a corresponding parameter is searched in the **parameters**-Object given on the function call. For Parameters like <CUSTOM_KEYWORD>, a camelcase parameter customKeyword is expected.

If it is required and not provided, an error such as the following is forced by the function, preventing incorrect naming to be deployed.

![example.error.missingParameter](./_resources/example.error.mssingParameter.png)

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
