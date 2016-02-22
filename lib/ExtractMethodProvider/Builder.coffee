{Range} = require 'atom'

ParameterParser = require './ParameterParser'

module.exports =

class Builder

    ###*
     * The body of the new method that will be shown in the preview area.
     *
     * @type {String}
    ###
    methodBody: ''

    ###*
     * The tab string that is used by the current editor.
     *
     * @type {String}
    ###
    tabText: ''

    ###*
     * The php-integrator-base service.
     *
     * @type {Service}
    ###
    service: null

    ###*
     * A range of the selected/highlighted area of code to analyse.
     *
     * @type {Range}
    ###
    selectedBufferRange: null

    ###*
     * The text editor to be analysing.
     *
     * @type {TextEditor}
    ###
    editor: null

    ###*
     * The parameter parser that will work out the parameters the
     * selectedBufferRange will need.
     *
     * @type {ParameterParser}
    ###
    parameterParser: null

    ###*
     * All the variables to return
     *
     * @type {Array}
    ###
    returnVariables: null

    ###*
     * Constructor.
     *
     * @param  {Service} service php-integrator-base service
    ###
    constructor: (service) ->
        @setService service
        @parameterParser = new ParameterParser @service.parser

    ###*
     * Sets the method body to use in the preview.
     *
     * @param {String} text
    ###
    setMethodBody: (text) ->
        @methodBody = text

    ###*
     * The tab string to use when genereating new method.
     *
     * @param {String} tab
    ###
    setTabText: (tab) ->
        @tabText = tab

    ###*
     * Set the php-integrator-base service to be used.
     *
     * @param {Service} service
    ###
    setService: (service) ->
        @service = service

    ###*
     * Set the selectedBufferRange to analyse.
     *
     * @param {Range} range [description]
    ###
    setSelectedBufferRange: (range) ->
        @selectedBufferRange = range

    ###*
     * Set the TextEditor to be used when analysing the selectedBufferRange
     *
     * @param {TextEditor} editor [description]
    ###
    setEditor: (editor) =>
        @editor = editor
        @setTabText(editor.getTabText())
        @setSelectedBufferRange(editor.getSelectedBufferRange())

    ###*
     * Builds the new method from the selectedBufferRange and settings given.
     *
     * The settings parameter should be an object with these properties:
     *   - methodName (string)
     *   - visibility (string) ['private', 'protected', 'public']
     *   - tabs (boolean)
     *   - generateDocs (boolean)
     *
     * @param  {Object} settings
     *
     * @return {String}
    ###
    buildMethod: (settings) =>
        parameters = @parameterParser.findParameters(
            @editor,
            @selectedBufferRange
        )

        if @returnVariables == null
            @returnVariables = @workOutReturnVariables @parameterParser.getVariableDeclarations()

        parameterNames = parameters.map (item) ->
            return item.name

        newMethod = @buildLine "#{settings.visibility} function #{settings.methodName}(#{parameterNames.join ', '})", settings.tabs
        newMethod += @buildLine "{", settings.tabs
        for line in @methodBody.split('\n')
            newMethod += @buildLine "#{line}", settings.tabs
        newMethod += @buildReturnLine @returnVariables, settings.tabs
        newMethod += @buildLine "}", settings.tabs

        if settings.generateDocs
            docs = @buildDocumentation settings.methodName, parameters, settings.tabs
            newMethod = docs + newMethod

        return newMethod

    ###*
     * Build the line that calls the new method and the variable the method
     * to be assigned to.
     *
     * @param  {String} methodName
     * @param  {String} variable   [Optional]
     *
     * @return {[type]}            [description]
    ###
    buildMethodCall: (methodName, variable) =>
        parameters = @parameterParser.findParameters(
            @editor,
            @selectedBufferRange
        )

        parameterNames = parameters.map (item) ->
            return item.name

        methodCall = "$this->#{methodName}(#{parameterNames.join ', '});"

        if variable != undefined
            methodCall = "$#{variable} = #{methodCall}"
        else
            if @returnVariables != null
                if @returnVariables.length == 1
                    methodCall = "#{@returnVariables[0].name} = #{methodCall}"
                else if @returnVariables.length > 1
                    variables = @returnVariables.reduce (previous, current) ->
                        if typeof previous != 'string'
                            previous = previous.name

                        return previous + ', ' + current.name

                    methodCall = "list(#{variables}) = #{methodCall}"

        return methodCall

    ###*
     * Builds the docblock for the given method and parameters.
     *
     * @param  {String}  methodName
     * @param  {Array}   parameters
     * @param  {Boolean} tabs       = false
     *
     * @return {String}
    ###
    buildDocumentation: (methodName, parameters, tabs = false) =>
        docs = @buildLine "/**", tabs
        docs += @buildDocumentationLine "[#{methodName} description]", tabs

        if parameters.length > 0
            docs += @buildLine " *", tabs

        for parameter in parameters
            docs += @buildDocumentationLine "@param #{parameter.type} #{parameter.name} [description]", tabs

        docs += @buildLine " */", tabs

        return docs

    ###*
     * Builds a single line of the new method. This will add a new line to the
     * end and add any tabs that are needed (if requested).
     *
     * @param  {String}  content
     * @param  {Boolean} tabs    = false
     *
     * @return {String}
    ###
    buildLine: (content, tabs = false) ->
        if tabs
            content = "#{@tabText}#{content}"
        return content + "\n"

    ###*
     * Builds a documentation line. This uses buildLine function just with
     * " * " prefixed to the content.
     *
     * @param  {String}  content
     * @param  {Boolean} tabs    = false
     *
     * @return {String}
    ###
    buildDocumentationLine: (content, tabs = false) ->
        content = " * #{content}"
        return @buildLine(content, tabs)

    ###*
     * Performs any clean up needed with the builder.
    ###
    cleanUp: ->
        @parameterParser.removeCachedParameters(@editor, @selectedBufferRange)
        @returnVariables = null
        @parameterParser.cleanUp()

    ###*
     * Works out which variables need to be returned from the new method.
     *
     * @param  {Array} variableDeclarations
     *
     * @return {Array}
    ###
    workOutReturnVariables: (variableDeclarations) ->
        startPoint = @selectedBufferRange.end
        scopeRange = @parameterParser.getRangeForCurrentScope(@editor, startPoint)

        lookupRange = new Range(startPoint, scopeRange.end)

        textAfterExtraction = @editor.getTextInBufferRange lookupRange
        allVariablesAfterExtraction = textAfterExtraction.match /\$[a-zA-Z0-9]+/g

        return null if allVariablesAfterExtraction == null

        variableDeclarations = variableDeclarations.filter (variable) =>
            for variables in allVariablesAfterExtraction
                if variables == variable.name
                    return true

            return false

        return variableDeclarations

    ###*
     * Builds the return statement for the new method.
     *
     * @param  {Array}   variableDeclarations
     * @param  {Boolean} tabs
     * @param  {String}  arrayType ['word', 'brackets']
     *
     * @return {String}
    ###
    buildReturnLine: (variableDeclarations, tabs, arrayType = 'word') ->
        if variableDeclarations == null
            return ''

        content = @buildLine '', false
        if variableDeclarations.length == 1
            content += @buildLine "#{@tabText}return #{variableDeclarations[0].name};", tabs
            return content

        if variableDeclarations.length > 1
            variables = variableDeclarations.reduce (previous, current) ->
                if typeof previous != 'string'
                    previous = previous.name

                return previous + ', ' + current.name

            if arrayType == 'brackets'
                variables = "[#{variables}]"
            else
                variables = "array(#{variables})"

            content += @buildLine "#{@tabText}return #{variables};", tabs
            return content

        return ''
