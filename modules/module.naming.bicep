/*

#################################################################
### Export a Function for generating names

*/

@export()
func nameGenerator(resourceType string, schema object, parameters object) string =>
  last([
    // Check whether all required parameters are provided in the paremeters object
    map(
      schema.resources[resourceType].required,
      // NOTE: 
      // Bicep apperently is case-insensitive here
      // 'customparameter', 'CUSTOMPARAMETER', etc. all access 'customParameter' regardless of casing
      required => parameters[replace(required, '_', '')]
    )

    // Generate the name from the pattern provided via the schema object.
    join(
      filter(
        map(
          map(
            map(
              map(
                map(
                  schema.resources[resourceType].pattern,
                  // Replace location with correct shortname
                  segment_Location =>
                    segment_Location == '<LOCATION>' ? schema.locations[parameters.location] : segment_Location
                ),
                // Replace segments with unique string
                segment_Unique =>
                  segment_Unique == '<UNIQUE_STRING>' ? uniqueString(resourceGroup().id) : segment_Unique
              ),

              // Transform any keyword from <CUSTOM_KEYWORD> to CUSTOMKEYWORD.
              segment_Transform =>
                ({
                  isKeyWord: startsWith(segment_Transform, '<') && endsWith(segment_Transform, '>')
                  keyWord: substring(segment_Transform, 1, length(segment_Transform) - 2)
                  parameter: startsWith(segment_Transform, '<') && endsWith(segment_Transform, '>')
                    ? replace(substring(segment_Transform, 1, length(segment_Transform) - 2), '_', '')
                    : segment_Transform
                })
            ),
            // Replace segments in pattern with correct parameters, if it is a keyword < >
            segment_Parameter =>
              !segment_Parameter.isKeyWord
                ? segment_Parameter.parameter
                // Replace only if a parameter is present in the parameters-object. The check for required parameters is already done before that.
                : format(
                    // Apply special formatting if defined for a parameter
                    schema.resources[resourceType].formats[?segment_Parameter.keyWord] ?? '{0}',
                    parameters[?segment_Parameter.parameter]
                  )
          ),
          // Make all segments lowercase for resources like storage accounts
          segment_Lowercase =>
            schema.resources[resourceType].enforceAllLowerCase ? toLower(segment_Lowercase) : segment_Lowercase
        ),
        // Filter out empty segment and unmatched segments before join.
        segment_Filter => !empty(segment_Filter) && !contains(segment_Filter, '<') && !contains(segment_Filter, '>')
      ),
      schema.resources[resourceType].delimiter
    )
  ])

/*

#################################################################
### Define naming schema for each resource

NOTE:
  multiple different Schemas can be created in this or other modules and later provided to the function, 
  resulting in different names to handle multiple naming conventions.
  
  nameGenerator(
    'Microsoft.KeyVault/vaults',
    // Provide different schemas for different naming conventions
    namingSchemaReference, 
    {
      name: 'secrets'
      location: location
      environment: environment
    }
  )
*/

@export()
var namingSchemaReference = {
  locations: {
    'West Europe': 'euwe'
    westeurope: 'euwe'

    'Germany North': 'geno'
    germanynorth: 'geno'

    'Germany West Central': 'gewc'
    germanywestcentral: 'gewc'
  }

  resources: {
    'Microsoft.Web/sites/functionApp': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['func', '<PREFIX>', '<NAME>', '<LOCATION>', '<ENVIRONMENT>', '<POSTFIX_INDEX>']
      required: [
        'NAME'
        'LOCATION'
        'ENVIRONMENT'
        'POSTFIX_INDEX'
      ]
      formats: {
        POSTFIX_INDEX: '{0:000}'
      }
    }

    'Microsoft.KeyVault/vaults': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['kv', '<PREFIX>', '<NAME>', '<ENVIRONMENT>', '<UNIQUE_STRING>']
      required: [
        'NAME'
        'ENVIRONMENT'
      ]
      formats: {}
    }

    'Microsoft.Web/sites/functions': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['func', '<PREFIX>', '<NAME>', '<LOCATION>', '<ENVIRONMENT>', '<POSTFIX_INDEX>']
      required: [
        'NAME'
        'LOCATION'
        'ENVIRONMENT'
        'POSTFIX_INDEX'
      ]
      formats: {
        POSTFIX_INDEX: '{0:000}'
      }
    }

    'Microsoft.Storage/storageAccounts': {
      enforceAllLowerCase: true

      delimiter: ''
      pattern: ['st', '<PREFIX>', '<NAME>', '<LOCATION>', '<ENVIRONMENT>', '<POSTFIX_INDEX>']
      required: [
        'NAME'
        'LOCATION'
        'ENVIRONMENT'
      ]
      formats: {
        POSTFIX_INDEX: '{0:000}'
      }
    }

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
      formats: {
        POSTFIX_INDEX: '{0:000}'
      }
    }

    'Microsoft.Network/virtualNetworks/subnets': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['snet', '<PREFIX>', '<NAME>', '<LOCATION>', '<ENVIRONMENT>', '<POSTFIX_INDEX>']
      required: [
        'NAME'
        'LOCATION'
        'ENVIRONMENT'
        'POSTFIX_INDEX'
      ]
      formats: {
        POSTFIX_INDEX: '{0:000}'
      }
    }
  }
}
