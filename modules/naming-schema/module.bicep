/*

  These are some example naming schema that can be imported in a Bicep file.

  Each naming schema is a separate file, so that they can be maintained separately.

*/

@export()
var defaultSchema = import_defaultSchema

import { schemaReference as import_defaultSchema } from './schema/schema.default.bicep'


