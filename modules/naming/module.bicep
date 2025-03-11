import { nameGenerator } from './func.name.bicep'

@export()
@description('Define naming parameters for this resource. Any provided naming parameters will be used with higher priorty of the inherited naming parameter.')
type typeNaming = {
  index: int?
  overwrite: string?
  *: string?
}

/*

  #######################################################
  ## Exported Naming Generation Function.

  ## The following is a wrapper for an imported function, so that the long function can be maintained in a separate file.

*/

@export()
func nameKind(resourceType string, kind string, schema object, parameters object) string =>
  nameGenerator(resourceType, kind, schema, parameters)

@export()
func name(resourceType string, schema object, parameters object) string =>
  nameGenerator(resourceType, null, schema, parameters)

/*

  #######################################################
  ### Special Resource Group Name Generation Function.

*/

@export()
@description('This is a special shortcut function for generating a resource group name. This is usefull for subscription scope deployments, so the resource group reference can be passed to the following modules, while still having an easy interface to use the naming module with.')
func nameResourceGroup(
  location string?,
  naming {
    index: int?
    overwrite: string?
    *: string?
  },
  schema object
) string =>
  name(
    'Microsoft.Resources/resourceGroups',
    schema,
    union(
      {
        location: location
      },
      naming ?? {}
    )
  )
