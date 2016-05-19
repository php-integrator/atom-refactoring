module.exports =

class TypeHelper
    ###*
     * @param {String|null} typeSpecification
     * @param {boolean}     allowPhp7
     *
     * @return {Object|null}
    ###
    getTypeHintForTypeSpecification: (typeSpecification, allowPhp7) ->
        return null if not typeSpecification

        types = @getDocblockTypesFromDocblockTypeSpecification(typeSpecification)

        return @getTypeHintForDocblockTypes(types, allowPhp7)

    ###*
     * @param {String|null} typeSpecification
     *
     * @return {Array}
    ###
    getDocblockTypesFromDocblockTypeSpecification: (typeSpecification) ->
        return [] if not typeSpecification?
        return typeSpecification.split('|')

    ###*
     * @param {Array}   types
     * @param {boolean} allowPhp7
     *
     * @return {Object|null}
    ###
    getTypeHintForDocblockTypes: (types, allowPhp7) ->
        isNullable = false

        types = types.filter (type) =>
            if type == 'null'
                isNullable = true

            return type != 'null'

        typeHint = null
        previousTypeHint = null

        for type in types
            typeHint = @getTypeHintForDocblockType(type, allowPhp7)

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
     * @param {String|null} type
     * @param {boolean}     allowPhp7
     *
     * @return {String|null}
    ###
    getTypeHintForDocblockType: (type, allowPhp7) ->
        return null if not type?
        return type if @isClassType(type, allowPhp7)
        return @getScalarTypeHintForDocblockType(type, allowPhp7)

    ###*
     * @param {String|null} type
     * @param {boolean}     allowPhp7
     *
     * @return {boolean}
    ###
    isClassType: (type, allowPhp7) ->
        return if (@getScalarTypeHintForDocblockType(type, allowPhp7) == false) then true else false

    ###*
     * @param {String|null} type
     * @param {boolean}     allowPhp7
     *
     * @return {String|null|false} Null if the type is recognized, but there is no type hint available, false of the
     *                             type is not recognized at all, and the type hint itself if it is recognized and there
     *                             is a type hint.
    ###
    getScalarTypeHintForDocblockType: (type, allowPhp7) ->
        return null if not type?

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

        return false

    ###*
     * Takes a type list (list of type objects) and turns them into a single docblock type specification.
     *
     * @param {Array} typeList
     *
     * @return {String}
    ###
    buildTypeSpecificationFromTypeArray: (typeList) ->
        typeNames = typeList.map (type) ->
            return type.type

        return @buildTypeSpecificationFromTypes(typeNames)

    ###*
     * Takes a list of type names and turns them into a single docblock type specification.
     *
     * @param {Array} typeNames
     *
     * @return {String}
    ###
    buildTypeSpecificationFromTypes: (typeNames) ->
        return typeNames.join('|')
