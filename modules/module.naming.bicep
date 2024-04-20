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
                  map(
                    schema.resources[resourceType].pattern,
                    // Replace location with correct shortname
                    segment_Location =>
                      segment_Location == '<LOCATION>' ? schema.locations[parameters.location] : segment_Location
                  ),
                  // Replace postfix with correct format based on index
                  segment_PostfixIndex =>
                    segment_PostfixIndex == '<POSTFIX_INDEX>' && contains(parameters, 'postfixIndex')
                      ? format('{0:000}', parameters.postfixIndex)
                      : segment_PostfixIndex
                ),
                // Replace segments with unique string
                segment_Unique =>
                  segment_Unique == '<UNIQUE_STRING>' ? uniqueString(resourceGroup().id) : segment_Unique
              ),

              // Transform any keyword from <CUSTOM_KEYWORD> to CUSTOMKEYWORD.
              segment_Transform =>
                ({
                  isKeyWord: startsWith(segment_Transform, '<') && endsWith(segment_Transform, '>')
                  name: startsWith(segment_Transform, '<') && endsWith(segment_Transform, '>')
                    ? replace(substring(segment_Transform, 1, length(segment_Transform) - 2), '_', '')
                    : segment_Transform
                })
            ),
            // Replace segments in pattern with correct parameters, if it is a keyword < >
            segment_Parameter =>
              !segment_Parameter.isKeyWord
                ? segment_Parameter.name
                // Replace only if a parameter is present in the parameters-object.
                : contains(parameters, segment_Parameter.name) ? parameters[segment_Parameter.name] : ''
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
    }
  }
}
