module.exports =

class TypeHelper
    ###*
     * @param  {String}  typeSpecification
     * @param  {boolean} allowPhp7
     *
     * @return {Object|null}
    ###
    getTypeHintForTypeSpecification: (typeSpecification, allowPhp7) ->
        types = typeSpecification.split('|')

        isNullable = false

        types = types.filter (type) =>
            if type == 'null'
                isNullable = true

            return type != 'null'

        typeHint = null
        previousTypeHint = null

        for type in types
            typeHint = @getTypeHintForType(type, allowPhp7)

            if previousTypeHint? and typeHint != previousTypeHint
                # Several different type hints are necessary, we can't provide a common denominator.
                return null

            previousTypeHint = typeHint

        return null if not typeHint?

        return {
            typeHint   : typeHint
            isNullable : isNullable
        }

    ###*
     * @param  {String}  type
     * @param  {boolean} allowPhp7
     *
     * @return {String|null}
    ###
    getTypeHintForType: (type, allowPhp7) ->
        if allowPhp7
            return 'string'   if type == 'string'
            return 'int'      if type == 'int'
            return 'bool'     if type == 'bool'
            return 'float'    if type == 'float'
            return 'resource' if type == 'resource'
            return 'bool'     if type == 'false'
            return 'bool'     if type == 'true'

        else
            return null       if type == 'string'
            return null       if type == 'int'
            return null       if type == 'bool'
            return null       if type == 'float'
            return null       if type == 'resource'
            return null       if type == 'false'
            return null       if type == 'true'

        return 'array'    if type == 'array'
        return 'callable' if type == 'callable'
        return 'self'     if type == 'self'
        return 'self'     if type == 'static'
        return 'array'    if /^.+\[\]$/.test(type)

        return null if type == 'object'
        return null if type == 'mixed'
        return null if type == 'void'
        return null if type == 'null'
        return null if type == 'parent'
        return null if type == '$this'

        # Must be a class type.
        return type
