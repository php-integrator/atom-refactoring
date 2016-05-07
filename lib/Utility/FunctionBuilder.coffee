module.exports =

class FunctionBuilder
    ###*
     * The access modifier (null if none).
    ###
    accessModifier: null

    ###*
     * Whether the method is static or not.
    ###
    isStatic: false

    ###*
     * Whether the method is abstract or not.
    ###
    isAbstract: null

    ###*
     * The name of the function.
    ###
    name: null

    ###*
     * The return type of the function. This could be set when generating PHP >= 7 methods.
    ###
    returnType: null

    ###*
     * The parameters of the function (a list of objects).
    ###
    parameters: null

    ###*
     * A list of statements to place in the body of the function.
    ###
    statements: null

    ###*
     * The tab text to insert on each line.
    ###
    tabText: ''

    ###*
     * Constructor.
    ###
    constructor: () ->
        @parameters = []
        @statements = []

    ###*
     * Makes the method public.
     *
     * @return {FunctionBuilder}
    ###
    makePublic: () ->
        @accessModifier = 'public'
        return this

    ###*
     * Makes the method private.
     *
     * @return {FunctionBuilder}
    ###
    makePrivate: () ->
        @accessModifier = 'private'
        return this

    ###*
     * Makes the method protected.
     *
     * @return {FunctionBuilder}
    ###
    makeProtected: () ->
        @accessModifier = 'protected'
        return this

    ###*
     * Makes the method global (i.e. no access modifier is added).
     *
     * @return {FunctionBuilder}
    ###
    makeGlobal: () ->
        @accessModifier = null
        return this

    ###*
     * Sets whether the method is static or not.
     *
     * @param {bool} isStatic
     *
     * @return {FunctionBuilder}
    ###
    setIsStatic: (@isStatic) ->
        return this

    ###*
     * Sets whether the method is abstract or not.
     *
     * @param {bool} isAbstract
     *
     * @return {FunctionBuilder}
    ###
    setIsAbstract: (@isAbstract) ->
        return this

    ###*
     * Sets the name of the function.
     *
     * @param {String} name
     *
     * @return {FunctionBuilder}
    ###
    setName: (@name) ->
        return this

    ###*
     * Sets the return type.
     *
     * @param {String|null} returnType
     *
     * @return {FunctionBuilder}
    ###
    setReturnType: (@returnType) ->
        return this

    ###*
     * Sets the parameters to add.
     *
     * @param {Array} parameters
     *
     * @return {FunctionBuilder}
    ###
    setParameters: (@parameters) ->
        return this

    ###*
     * Adds a parameter to the parameter list.
     *
     * @param {Object} parameter
     *
     * @return {FunctionBuilder}
    ###
    addParameter: (parameter) ->
        @parameters.push(parameter)
        return this

    ###*
     * Sets the statements to add.
     *
     * @param {Array} statements
     *
     * @return {FunctionBuilder}
    ###
    setStatements: (@statements) ->
        return this

    ###*
     * Adds a statement to the body of the function.
     *
     * @param {String} statement
     *
     * @return {FunctionBuilder}
    ###
    addStatement: (statement) ->
        @statements.push(statement)
        return this

    ###*
     * Sets the tab text to prepend to each line.
     *
     * @param {String} tabText
     *
     * @return {FunctionBuilder}
    ###
    setTabText: (@tabText) ->
        return this

    ###*
     * Builds the method using the preconfigured settings.
     *
     * @return {String}
    ###
    build: () =>
        signatureLine = ''

        if @isAbstract
            signatureLine += 'abstract '

        if @accessModifier?
            signatureLine += "#{@accessModifier} "

        if @isStatic
            signatureLine += 'static '


        signatureLine += "function #{@name}("

        for parameter, i in @parameters
            if i > 0
                signatureLine += ', '

            if parameter.typeHint?
                signatureLine += "#{parameter.typeHint} "

            if parameter.isVariadic
                signatureLine += '...'

            if parameter.isReference
                signatureLine += '&'

            signatureLine += "$#{parameter.name}"

            if parameter.defaultValue?
                signatureLine += " = #{parameter.defaultValue}"

        signatureLine += ')'

        if @returnType?
            signatureLine += ": #{@returnType}"

        output = ''
        output += @buildLine(signatureLine)
        output += @buildLine('{')

        for statement in @statements
            output += @tabText + @buildLine(statement)

        output += @buildLine('}')

        return output

    ###*
     * @param {String} content
     *
     * @return {String}
    ###
    buildLine: (content) ->
        return "#{@tabText}#{content}\n"
