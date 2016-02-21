ParameterParser = require './ParameterParser'

module.exports =

class Builder

    methodBody: ''

    tabText: ''

    service: null

    selectedBufferRange: null

    editor: null

    parameterParser: null

    constructor: ->
        @parameterParser = new ParameterParser

    setMethodBody: (text) ->
        @methodBody = text

    setTabText: (tab) ->
        @tabText = tab

    setService: (service) ->
        @service = service

    setSelectedBufferRange: (range) ->
        @selectedBufferRange = range

    setEditor: (editor) =>
        @editor = editor
        @setTabText(editor.getTabText())
        @setSelectedBufferRange(editor.getSelectedBufferRange())

    buildMethod: (settings) =>
        parameters = @parameterParser.findParameters(
            @editor,
            @selectedBufferRange
        )
        newMethod = @buildLine "#{settings.visibility} function #{settings.methodName}(#{parameters.join ', '})", settings.tabs
        newMethod += @buildLine "{", settings.tabs
        for line in @methodBody.split('\n')
            newMethod += @buildLine "#{line}", settings.tabs
        newMethod += @buildLine "}", settings.tabs

        if settings.generateDocs
            docs = @buildDocumentation settings.methodName, parameters, settings.tabs
            newMethod = docs + newMethod

        return newMethod

    buildMethodCall: (methodName, variable) =>
        parameters = @parameterParser.findParameters(
            @editor,
            @selectedBufferRange
        ).join(', ')
        methodCall = "$this->#{methodName}(#{parameters});"

        if variable != undefined
            methodCall = "$#{variable} = #{methodCall}"

        return methodCall

    buildDocumentation: (methodName, parameters, tabs = false) =>
        docs = @buildLine "/**", tabs
        docs += @buildDocumentationLine "[#{methodName} description]", tabs

        if parameters.length > 0
            docs += @buildLine " *", tabs

        for parameter in parameters
            docs += @buildDocumentationLine "@param [type] #{parameter} [description]", tabs

        docs += @buildLine " */", tabs

        return docs

    buildLine: (content, tabs = false) ->
        if tabs
            content = "#{@tabText}#{content}"
        return content + "\n"

    buildDocumentationLine: (content, tabs = false) ->
        content = " * #{content}"
        return @buildLine(content, tabs)

    cleanUp: ->
        @parameterParser.removeCachedParameters(@editor, @selectedBufferRange)
