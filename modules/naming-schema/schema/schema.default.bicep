/*

  This naming schema follows mostly the pattern:

    XX-<?PREFIX>-<LOCATION>-<ENVIRONMENT>-<NAME>

  - This naming includes LOCATION, ENVIRONMENT and NAME, which are used to generate unique names for resources.
  - NAME is a static string, which is used to identify the resource. The name has to be seperate for resources of the same type.
  


*/

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
