# Bicep Naming Module

<div align="center">

<br><br>

![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Version](https://img.shields.io/badge/version-5.5.0-blue?style=for-the-badge)

A consistent, schema-driven approach to Azure resource naming in Bicep.

</div>

## 🙏 Acknowledgments

- ☁️ **Microsoft** for [Azure Bicep](https://github.com/Azure/bicep) and the amazing IaC tooling
- 🔤 **CAF Naming Conventions** for the abbreviation guidelines this module is built around
- 💖 **Open Source** contributors and the Azure community for inspiration

---

## Why This Module?

- **Centralized Naming** — maintain conventions in one place, not scattered across modules.
- **Consistency** — all resources follow the same logic, regardless of scope.
- **Extensible** — add abbreviations, locations, or patterns without touching existing code.
- **Any Scope Supported** — custom functions can be imported and used at any scope, unlike Bicep modules.
- **Validation** — built-in range checks on index parameters catch errors at deploy time.

---

## 📁 Project Structure

```
📦 Bicep Naming Module
├── 📁 naming/
│   ├── 📁 generator/
│   │   ├── ⚙️ func.name.bicep           # Core naming logic
│   │   ├── 📦 module.bicep              # Exports: genName, genNameId
│   │   └── 📋 version.json
│   └── 📁 schema/
│       ├── 📦 module.bicep              # Exports: schema (default, index-based)
│       ├── 📋 version.json
│       └── 📁 schema/
│           ├── 🗂️ schema.default.bicep  # Default naming schema
│           ├── 🗂️ schema.index-based.bicep
│           ├── 🔤 var.abbr.bicep        # Resource type abbreviations
│           └── 🌍 var.location.bicep    # Location short names
├── 📁 examples/
│   ├── 📁 example.naming.001/           # Basic usage examples
│   ├── 📁 example.naming.errors/        # Validation & error examples
│   └── 📁 example.naming.subsScope/     # Subscription-scope example
└── 📖 README.md
```

---

## 🚀 Quick Start

### Basic Resource Naming

```bicep
import { schema } from '../../naming/schema/module.bicep'
import { genName } from '../../naming/generator/module.bicep'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: genName('Microsoft.Storage/storageAccounts', schema.default, location, {
    name: 'files'
    environment: environment
  })
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {}
}
```

### Kind-based Differentiation

Use `::kind` to distinguish between resources of the same type:

```bicep
import { schema } from '../../naming/schema/module.bicep'
import { genName } from '../../naming/generator/module.bicep'

output functionAppName string = genName('Microsoft.Web/sites::function', schema.default, location, {
  name: 'apps'
  environment: environment
  index: 1
})

output appServiceName string = genName('Microsoft.Web/sites::app', schema.default, location, {
  name: 'apps'
  environment: environment
  index: 1
})
```

---

## ⚙️ How It Works

### Generator Functions

| Function | Description |
|---|---|
| `genName(resourceType, schema, location, params)` | Name from resource type + parameters |
| `genName(resourceType::kind, schema, location, params)` | Name with kind-based abbreviation |
| `genNameId(resourceType, id, schema, location, params)` | Name with a unique identifier |
| `genNameId(resourceType::kind, id, schema, location, params)` | Name with kind + id |

### Naming Schema

The schema bundles abbreviations, location mappings, patterns, and validation rules into a single reusable Bicep object. Schemas can live in a separate repo, file, or container registry — anything Bicep can import from.

#### Location Mappings

```bicep
var defaultLocations = {
  global:              'glob'
  'West Europe':       'euwe'
  westeurope:          'euwe'
  'Germany North':     'geno'
  germanynorth:        'geno'
  'Germany West Central': 'gewc'
  germanywestcentral:  'gewc'
}
```

#### Abbreviations

Resource types map to a short prefix. Append `::kind` to give the same resource type different abbreviations depending on how it is used — for example a Function App and an App Service are both `Microsoft.Web/sites`, but carry different prefixes:

```bicep
var defaultAbbreviations = {
  'Microsoft.Storage/storageAccounts':             'st'
  'Microsoft.KeyVault/vaults':                     'kv'
  'Microsoft.Search/searchServices':               'srch'
  'Microsoft.MachineLearningServices/workspaces':  'mlw'

  // Same resource type, different abbreviation per kind
  'Microsoft.Web/sites::default':                  'app'   // genName('Microsoft.Web/sites', ...)
  'Microsoft.Web/sites::app':                      'app'   // genName('Microsoft.Web/sites::app', ...)
  'Microsoft.Web/sites::function':                 'func'  // genName('Microsoft.Web/sites::function', ...)
}
```

`genNameId` works the same way but additionally accepts an `id` — a string that maps to a specific pattern entry inside the schema. Use it when the same resource type needs distinct naming rules per instance rather than per kind (e.g. two different VNets with completely different pattern shapes).

```bicep
// id takes precedence over kind when both are defined in the pattern map
genNameId('Microsoft.Network/virtualNetworks', 'hub',  schema.default, location, { name: 'network', environment: environment })
genNameId('Microsoft.Network/virtualNetworks', 'spoke', schema.default, location, { name: 'network', environment: environment })
```

### Pattern Syntax

Patterns are strings with placeholder tokens that get replaced at evaluation time:

| Syntax | Behavior |
|---|---|
| `<PARAMETER>` | Required parameter — fails if missing |
| `<?PARAMETER>` | Optional parameter — omitted if not provided |
| `<?PARAMETER;-{0}>` | Optional with separator — separator is omitted together with the value |
| `<PARAMETER;{0:000}>` | Format string — pads index with leading zeros |
| `<PARAMETER;{0}>` | Custom format string (Bicep `format()` syntax) |

**Special parameters:**

| Token | Description |
|---|---|
| `<TYPE>` | Resolved abbreviation for the resource type |
| `<LOCATION>` | Short location name from the locations map |
| `<INDEX>` | Current loop index |
| `<KEY>` | Current loop key (when iterating with `items()`) |
| `<KIND>` | The kind or id suffix |
| `<ID>` | points specifically to the id when provided |
| `<UNIQUE_STRING_N>` | Unique hash from resource group name (N = 0–9, resource group scope only) |

### Pattern Entries

```bicep
patterns: {
  // Fallback used when no specific pattern is defined
  default: '<TYPE><?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME><?INDEX;-{0:00}>'

  // Single pattern for one resource type (INLINE:: prefix required)
  'INLINE::Microsoft.Storage/storageAccounts': 'st<?PREFIX><LOCATION><ENVIRONMENT><NAME>'
  'INLINE::Microsoft.KeyVault/vaults':         'kv<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<UNIQUE_STRING_5>'

  // Multiple patterns per resource type, selected by kind or id
  'Microsoft.Compute/disks': {
    data: '<TYPE><INDEX;{0:00}>-<NAME>-<ENVIRONMENT>'
    os:   '<TYPE>-<NAME>-<ENVIRONMENT>'
  }
}
```

Pattern resolution order: **kind-specific → default kind → global default → error**

### Validation

```bicep
validate: {
  default: {
    INDEX: { range: [0, 999] }
  }
  'Microsoft.Compute/disks': {
    INDEX: { range: [0, 10] }
  }
}
```

### Value Mappings

```bicep
mappings: {
  environment: {
    development: 'dev'
    production:  'prod'
  }
}
```

---

## 🗺️ Schema at a Glance

A naming schema is a plain Bicep object — store it anywhere Bicep can import from (local file, private registry, separate repo).

```bicep
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

  mappings: {
    // Will map any entry of parameter ENVIRONMENT to another value.
    // 
    environment: {
      development: 'dev'
      production: 'prod'
    }
  }

  /*
    NOTE:
    - <PARAMETER>        : Key words that are replaced by parameters.
    - <?PARAMETER>       : ? Defines Optional parameters, which are omitted if not set.
    - <?PARAMETER;-{0}>  : This format is preferred so that the separator '-' is only set if the parameter is present.
    - <PARAMETER;{0:000}>: This format is preferred so that the index is always formatted with leading zeros.	
    - <PARAMETER;{0}>    : The format after the ; is a format string and follows the syntax of the Bicep format('{0}', value) function.
    -                    : Everything else is interpreted as a normal string.

    SPECIAL PARAMETERS:
    The following only applies for modules, that correctly implement the naming schema.
    - <INDEX>           : points to the current index in an iteration. Needs to be set when calling genName()
    - <KEY>             : points to the current key in an iteration. Needs to be set when calling genName()
    - <KIND>            : points to the current kind or id
    - <ID>              : points specifically to the id when provided
    - <LOCATION>        : points to the location of the resource.
    - <UNIQUE_STRING_N> : is a unique id based on the resource group name. (N can be any number between 0 and 9)
  */

  // This is used to modify the index by adding and subtracting some amount
  indexModifier: 0
  patterns: {
    // The pattern search logic 
    // - Look for a pattern with the resourceType and a specific kind.
    // - If not found, look for a pattern with the resourceType and the default kind.
    // - If not found, fall back to the default pattern.
    // - If not found, fail with an error.

    /*
      The function can be call without an id or with an id.
      - genName(<resourceType>, <schema>, <location>, <parameters>)
      - genName(<resourceType>::<kind>, <schema>, <location>, <parameters>)

      The id allows identification of a specific resource.
      - genNameId(<resourceType>, <id>, <schema>, <location>, <parameters>)
      - genNameId(<resourceType>::<kind>, <id>, <schema>, <location>, <parameters>)
    */

    /*
      The entries can be defined in the following ways:
    
      A single pattern for a resource type:
      - INLINE:: must be prefixed for technical reasons. No way to tell strings apart from objects at bicep runtime.
      'INLINE::Microsoft.Web/serverfarms': '<TYPE>-<PROJECT_NAME>-<LOCATION>-<INDEX;{0:000}>'

      Different patterns for multiple <id> or <kind> of a resource type:
      - <id> takes precedence over <kind>.
      '<resource_type>': {
        default: '<TYPE>-<PROJECT_NAME>-<LOCATION>-<INDEX;{0:000}>'
        <kind>: '<TYPE>-<PROJECT_NAME>-<LOCATION>-<INDEX;{0:000}>'
        <id>: '<TYPE>-<PROJECT_NAME>-<LOCATION>-<INDEX;{0:000}>'
      }
    */

    ////////////////////////////////////////////////
    ////////////////////////////////////////////////

    // This is the main Fallback pattern for resources.
    // - If no specific pattern is defined for a resource type, this will be used. 
    // - When deactivated, any resource type without a specific pattern will fail with an error.
    //   like this: 'No pattern found for resourceType: INLINE::Microsoft.Web/serverfarms and kind: default'
    default: '<TYPE><?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME><?INDEX;-{0:00}>'

    ////////////////////////////////////////////////
    ///// Microsoft.KeyVault & Microsoft.Storage

    'INLINE::Microsoft.KeyVault/vaults': 'kv<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<UNIQUE_STRING_5>'
    'INLINE::Microsoft.Storage/storageAccounts': 'st<?PREFIX><LOCATION><ENVIRONMENT><NAME>'

    ////////////////////////////////////////////////
    ///// Microsoft.Compute Disks

    'Microsoft.Compute/disks': {
      data: '<TYPE><INDEX;{0:00}>-<NAME>-<ENVIRONMENT>'
      os: '<TYPE>-<NAME>-<ENVIRONMENT>'
    }

    ////////////////////////////////////////////////
    ///// Microsoft.ContainerRegistry

    'INLINE::Microsoft.ContainerRegistry/registries': 'acr<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME>'

    ////////////////////////////////////////////////
    ///// Microsoft.Network Virtual Network Peerings

    'INLINE::Microsoft.Network/virtualNetworks/virtualNetworkPeerings': 'vnet<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME>'

    ////////////////////////////////////////////////
    ///// Microsoft.Cdn Profiles & Related Resources

    'INLINE::Microsoft.Cdn/profiles': 'afd<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME>'
    'INLINE::Microsoft.Cdn/profiles/afdEndpoints': 'fde<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME>'
    'INLINE::Microsoft.Cdn/profiles/originGroups': 'ogrp<?PREFIX;-{0}>-<LOCATION>-<ENVIRONMENT>-<NAME>'
    'INLINE::Microsoft.Cdn/profiles/ruleSets': 'rset<?PREFIX><LOCATION><ENVIRONMENT><NAME>'

    ////////////////////////////////////////////////
    ///// Microsoft.Subscription Alias

    'INLINE::Microsoft.Subscription/alias': '<COMPANY>-<NAME>-<ENVIRONMENT>-subs-<IDENTIFIER;{0:0000}>'
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

`genName()` and `genNameId()` receive this object at call time — swap schemas between environments without changing any resource code.
