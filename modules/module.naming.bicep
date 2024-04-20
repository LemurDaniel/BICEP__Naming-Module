/*

#################################################################
### Export a Function for generating names

*/

@export()
func nameGenerator(resourceType string, schema object, parameters object) string =>
  last([
    /*
      Validation for missing required parameters
    */
    map(
      schema.resources[resourceType].required,
      // NOTE: 
      // Bicep apperently is case-insensitive here
      // 'customparameter', 'CUSTOMPARAMETER', etc. all access 'customParameter' regardless of casing
      required => parameters[replace(required, '_', '')]
    )

    /*
      Validation for parameter being in correct number range
    */
    map(
      filter(
        map(
          filter(
            items(schema.resources[resourceType].validate),
            // Filter if validation is of range and if to be validated parameter is in parameters-Object. Required-Check is already done above.
            validation => contains(parameters, replace(validation.key, '_', '')) && contains(validation.value, 'range')
          ),
          validation_Range =>
            ({
              key: validation_Range.key
              value: parameters[replace(validation_Range.key, '_', '')]
              range: validation_Range.value.range
            })
        ),
        validation_Range =>
          !(validation_Range.value >= validation_Range.range[0] && validation_Range.value <= validation_Range.range[1])
      ),
      // Force an error by accessing an invalid index
      validation_Errors =>
        parameters['${validation_Errors.key} with ${validation_Errors.value} is not in range: ${validation_Errors.range}']
    )

    /*
      Validation for parameter being in a set of values
    */
    map(
      filter(
        map(
          filter(
            items(schema.resources[resourceType].validate),
            // Filter if validation is of range and if to be validated parameter is in parameters-Object. Required-Check is already done above.
            validation => contains(parameters, replace(validation.key, '_', '')) && contains(validation.value, 'set')
          ),
          validation_Set =>
            ({
              key: validation_Set.key
              value: parameters[replace(validation_Set.key, '_', '')]
              set: validation_Set.value.set
            })
        ),
        validation_Set => !(contains(validation_Set.set, validation_Set.value))
      ),
      // Force an error by accessing an invalid index
      validation_Errors =>
        parameters['${validation_Errors.key} with ${validation_Errors.value} is not in set: ${validation_Errors.set}']
    )

    /*
      Final generating of name, after all checks are run
    */
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
                    schema.resources[resourceType].format[?segment_Parameter.keyWord] ?? '{0}',
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
    'Microsoft.KeyVault/vaults': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['kv', '<PREFIX>', '<NAME>', '<ENVIRONMENT>', '<UNIQUE_STRING>']
      required: [
        'NAME'
        'ENVIRONMENT'
      ]
      format: {}
      validate: {
        POSTFIX_INDEX: {
          range: [0, 999]
        }
      }
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
      format: {
        POSTFIX_INDEX: '{0:000}'
      }
      validate: {
        POSTFIX_INDEX: {
          range: [0, 999]
        }
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
      format: {
        POSTFIX_INDEX: '{0:000}'
      }
      validate: {
        POSTFIX_INDEX: {
          range: [0, 999]
        }
      }
    }

    'Microsoft.Compute/disks': {
      enforceAllLowerCase: true

      delimiter: '-'
      pattern: ['<DISK_TYPE>', '<DISK_LUN>', '<NAME>']
      required: [
        'DISK_TYPE'
        'DISK_LUN'
        'NAME'
      ]
      format: {
        DISK_LUN: '{0:00}'
      }
      validate: {
        DISK_LUN: {
          range: [0, 10]
        }
        DISK_TYPE: {
          set: [
            'osdisk'
            'datadisk'
            'shareddisk'
          ]
        }
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
      format: {
        POSTFIX_INDEX: '{0:000}'
      }
      validate: {
        POSTFIX_INDEX: {
          range: [0, 999]
        }
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
      format: {
        POSTFIX_INDEX: '{0:000}'
      }
      validate: {
        POSTFIX_INDEX: {
          range: [0, 999]
        }
      }
    }
  }
}
