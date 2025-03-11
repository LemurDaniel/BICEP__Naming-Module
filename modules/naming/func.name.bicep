@export()
func nameGenerator(
  resourceType string,
  kind string?,
  schema object,
  parameters {
    index: int?
    overwrite: string?
    *: string?
  }
) string =>
  nameGenerator2(
    // We are adding a '&' before and after each parameter, so that we can split it and get the correct segments.
    // Optimally this is some character that nobody in his right mind would use for naming.
    // Also we are not using ';', '?', as with those we are already controling custom formatting and optional parameters.
    // We are also not using the delimiter, because we may not want a delimiter between some segments and some resources don't have delimiters. (like storage accounts, container registries, etc.)
    split(
      replace(
        replace(
          !empty(kind)
            // This will fail indexing into an object without the key
            // but will not fail when indexing into a string
            ? schema.patterns[?resourceType][(kind ?? '')] ?? schema.patterns[?resourceType] ?? schema.patterns.default
            // The behaviour when no kind was specified
            : schema.patterns[?resourceType] ?? schema.patterns.default,
          '<',
          '&<'
        ),
        '>',
        '>&'
      ),
      '&'
    ),
    resourceType,
    schema,
    union(
      {
        index: 1
        key: null
        abbreviation: schema.abbreviations[resourceType][?(kind ?? '')] ?? schema.abbreviations[resourceType][?'*'] ?? schema.abbreviations[resourceType]
      },
      parameters
    )
  )

func nameGenerator2(pattern string[], resourceType string, schema object, parameters object) string =>
  // When OVERWRITE is set, the naming schema is not used and the name is directly returned.
  parameters.?OVERWRITE ?? last([
    /*

      Validation for missing required parameters.

    */

    // map__required_Present
    map(
      // filter__required_Filter
      filter(
        // map__required_Transform
        map(
          pattern,
          //
          // Transform segments into objects for easier handling
          required_Transform =>
            ({
              // This gives the segment with the control characters: <>, ?, _, ; removed
              value: split(
                replace(replace(replace(replace(required_Transform, '<', ''), '>', ''), '?', ''), '_', ''),
                ';'
              )[0]
              isParam: startsWith(required_Transform, '<') && endsWith(required_Transform, '>')
              isOptional: startsWith(required_Transform, '<?')
            })
        ),
        //
        // Filter out for conditions:
        // - isParam: Only parameters are required
        // - isOptional: Optional parameters are not required
        // - specialParams: Special params are not provided via parameters
        required_Filter =>
          required_Filter.isParam && !required_Filter.isOptional && !startsWith(required_Filter.value, 'UNIQUESTRING')
      ),
      //
      // Filter out all required parameters that are not provided
      // NOTE: 
      // Bicep apperently is case-insensitive here
      // 'customparameter', 'CUSTOMPARAMETER', etc. all access 'customParameter' regardless of casing
      required_Present => parameters[required_Present.value]
    )

    /*

      Validation for parameter being in correct number range.

    */
    // map__validation_Error
    map(
      // filter__validation_Valid
      filter(
        // map__validation_Apply
        map(
          // filter__validation_Filter
          filter(
            // map__validation_Transform
            map(
              // These applies validation settings, if they are defined in the schema.
              // First default settings are searched, then settings for the specific resource type are checked for.
              items(union(
                schema.?validate.?default ?? {},
                // It is designed to search for types that start with the resourceType, so that it can be used for multiple types.
                // For eaxample Microsoft.Compute/ => applies to all subtypes of Microsoft.Compute
                schema.?validate[?filter(objectKeys(schema.?validate ?? {}), key => startsWith(resourceType, key))[?0] ?? ''] ?? {}
              )),

              //
              // Transform validation settings into objects for easier handling
              validation_Transform =>
                ({
                  key: validation_Transform.key
                  value: parameters[?replace(validation_Transform.key, '_', '')]

                  validations: {
                    set: {
                      enabled: !empty(validation_Transform.value.?set)
                      value: validation_Transform.value.?set ?? []
                    }

                    range: {
                      enabled: !empty(validation_Transform.value.?range)
                      value: validation_Transform.value.?range ?? [0, 0]
                    }
                  }
                })
            ),
            //
            // Filter out empty parameter values
            // Check for required parameters is already done above
            // empty() can't be used here, because of possible integer values.
            validation_Filter => null != validation_Filter.value
          ),
          validation_Apply =>
            ({
              key: validation_Apply.key
              value: validation_Apply.value
              validations: validation_Apply.validations

              RangeValid: validation_Apply.validations.range.enabled
                ? int(validation_Apply.value) >= validation_Apply.validations.range.value[0] && int(validation_Apply.value) <= validation_Apply.validations.range.value[1]
                : true

              SetValid: validation_Apply.validations.set.enabled
                ? contains(validation_Apply.validations.set.value, validation_Apply.value)
                : true
            })
        ),
        //
        // Filter out all that have failed validation
        validation_Valid => !validation_Valid.RangeValid || !validation_Valid.SetValid
      ),
      validation_Error =>
        ({
          setInvalid: !validation_Error.SetValid
            ? parameters['${validation_Error.key} with ${validation_Error.value} is not in set: ${validation_Error.validations.set.value}']
            : null
          rangeInvalid: !validation_Error.RangeValid
            ? parameters['${validation_Error.key} with ${validation_Error.value} is not in range: ${validation_Error.validations.range.value}']
            : null
        })
    )

    /*

      Final generating of name, after all checks are run.

    */

    first([
      join(
        // map__segment_Unpack
        map(
          // map__segment_Lowercase
          map(
            // filter__segment_Filter
            filter(
              // map__segment_Parametery
              map(
                // map__segment_Tranform
                map(
                  // map__segment_Transform
                  map(
                    pattern,

                    //
                    // Transform segments into objects for easier handling
                    segment_Transform =>
                      ({
                        value: segment_Transform
                        isParam: startsWith(segment_Transform, '<') && endsWith(segment_Transform, '>')
                        isOptional: contains(segment_Transform, '?')

                        // Below are only relevent, when isParam is true
                        segment: replace(replace(replace(segment_Transform, '<', ''), '>', ''), '?', '')
                      })
                  ),

                  //
                  // Transform segments into objects for easier handling
                  segment_Transform =>
                    ({
                      value: segment_Transform.value
                      isParam: segment_Transform.isParam
                      isOptional: segment_Transform.isOptional

                      enforceLowerCase: schema.enforceLowerCase[?resourceType] ?? schema.enforceLowerCase.default

                      // Below are only relvent, when isParam is true
                      keyWord: split(segment_Transform.segment, ';')[0]

                      // If no other format is provided, use '{0}' as default
                      format: split(segment_Transform.segment, ';')[?1] ?? '{0}'

                      // When the keyWord is DISK_LUN, we want to search for DiskLun in parameters. 
                      // (Technically case-insensitive, we only don't want the '_' here)
                      parameter: replace(split(segment_Transform.segment, ';')[0], '_', '')
                    })
                ),

                //
                // Replace segments in pattern with correct parameters, if it is a parameter < >
                segment_Parameter =>
                  ({
                    enforceLowerCase: segment_Parameter.enforceLowerCase

                    value: concat(
                      map(filter([segment_Parameter], arg => !arg.isParam), arg => segment_Parameter.value),
                      map(
                        filter([segment_Parameter], arg => arg.keyWord == 'LOCATION'),
                        arg => schema.locations[parameters.location]
                      ),
                      map(
                        filter([segment_Parameter], arg => arg.keyWord == 'INDEX'),
                        arg => format(segment_Parameter.format, int(parameters.index) + int(schema.indexModifier))
                      ),
                      map(
                        filter([segment_Parameter], arg => startsWith(arg.keyWord, 'UNIQUE_STRING_')),
                        arg => substring(uniqueString(resourceGroup().name), 0, int(substring(arg.keyWord, 14, 1)))
                      ),
                      map(
                        filter([segment_Parameter], arg => arg.isOptional),
                        arg => contains(parameters, arg.parameter) ? format(arg.format, parameters[arg.parameter]) : ''
                      )
                    )[?0] ?? parameters[segment_Parameter.parameter]
                  })
              ),

              //
              // Filter out empty segment and unmatched segments before join.
              segment_Filter => !empty(segment_Filter.value)
            ),

            //
            // Enforce all lowercase, if defined in schema.
            segment_Lowercase =>
              ({
                value: segment_Lowercase.enforceLowerCase ? toLower(segment_Lowercase.value) : segment_Lowercase.value
              })
          ),

          // 
          // Unpack object and join segments to a string
          segment_Unpack => segment_Unpack.value
        ),

        //
        // Join splittet parameters into a single string again.
        ''
      )

      // This is still in an array of 1, so we can use the map-function on the single-value array.
    ]) ?? 'ERROR: Naming Generation failed.'
  ])
