import { nameGenerator } from './func.name.bicep'

@export()
@description('Define naming parameters for this resource. Any provided naming parameters will be used with higher priorty of the inherited naming parameter.')
type typeNaming = {
  index: int?
  overwrite: string?
  *: string?
}

@description('This is the type defintion for the naming config.')
@export()
type typeNamingSchema = {
  abbreviations: object
  locations: object

  mappings: object?
  indexModifier: int?
  enforceLowerCase: object?
  validate: object?

  patterns: object
}

/*

  #######################################################
  ## Exported Naming Generation Function.

  ## The following is a wrapper for an imported function, so that the long function can be maintained in a separate file.

*/

@export()
func genNameId(resourceType string, id string, schema object, location string, parameters object) string =>
  nameGenerator(resourceType, id, schema, {
    location: location
    ...parameters
  })

@export()
func genName(resourceType string, schema object, location string, parameters object) string =>
  nameGenerator(resourceType, null, schema, {
    location: location
    ...parameters
  })

@export()
func genNameIdExtraParam(
  resourceType string,
  kind string,
  schema object,
  location string,
  parameters object,
  extraParameters object
) string => genNameId(resourceType, kind, schema, location, { ...parameters, ...extraParameters })

@export()
func genNameExtraParam(resourceType string, schema object, location string, parameters object, extraParameters object) string =>
  genName(resourceType, schema, location, { ...parameters, ...extraParameters })

/*

  #######################################################
  ### Special Resource Group Name Generation Function.

*/

@export()
@description('This is a special shortcut function for generating a resource group name. This is usefull for subscription scope deployments, so the resource group reference can be passed to the following modules, while still having an easy interface to use the naming module with.')
func nameResourceGroup(
  location string,
  naming {
    index: int?
    overwrite: string?
    *: string?
  },
  schema object
) string => genName('Microsoft.Resources/resourceGroups', schema, location, naming)
