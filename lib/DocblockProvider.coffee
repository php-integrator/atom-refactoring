{Point} = require 'atom'

AbstractProvider = require './AbstractProvider'

DocblockBuilder = require './Utility/DocblockBuilder'

module.exports =

##*
# Provides docblock generation and maintenance capabilities.
##
class DocblockProvider extends AbstractProvider
    ###*
     * The docblock builder.
    ###
    docblockBuilder: null

    ###*
     * @inheritdoc
    ###
    activate: (service) ->
        super(service)

        @docblockBuilder = new DocblockBuilder()

    ###*
     * @inheritdoc
    ###
    getIntentionProviders: () ->
        return [{
            grammarScopes: ['entity.name.function.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                functionNameRange = textEditor.bufferRangeForScopeAtCursor('entity.name.function.php')
                functionName = textEditor.getTextInBufferRange(functionNameRange)

                return [
                    {
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generateDocblock(textEditor, bufferPosition, functionName)
                    }
                ]
        }]

    ###*
     * @inheritdoc
    ###
    deactivate: () ->
        super()

        if @docblockBuilder
            #@docblockBuilder.destroy()
            @docblockBuilder = null

    ###*
     * Executes the generation.
     *
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
     * @param {string}     functionName
    ###
    generateDocblock: (editor, triggerPosition, functionName) ->
        currentLine = triggerPosition.row

        successHandler = (currentClassName) =>
            nestedFailureHandler = () =>
                return

            if currentClassName
                nestedSuccessHandler = (classInfo) =>
                    return if not functionName of classInfo.methods

                    method = classInfo.methods[functionName]

                    zeroBasedStartLine = method.startLine - 1

                    if zeroBasedStartLine == currentLine
                        @generateDocblockFor(editor, method)

                @service.getClassInfo(currentClassName).then(nestedSuccessHandler, nestedFailureHandler)

            else
                nestedSuccessHandler = (globalFunctions) =>
                    return if not functionName of globalFunctions

                    method = globalFunctions[functionName]

                    zeroBasedStartLine = method.startLine - 1

                    if zeroBasedStartLine == currentLine
                        @generateDocblockFor(editor, method)

                @service.getGlobalFunctions().then(nestedSuccessHandler, nestedFailureHandler)

        failureHandler = () =>
            return

        @service.determineCurrentClassName(editor, triggerPosition).then(successHandler, failureHandler)

    generateDocblockFor: (editor, method) ->
        zeroBasedStartLine = method.startLine - 1

        parameters = []

        for parameter in method.parameters
            parameters.push({
                name: '$' + parameter.name
                type: if parameter.type then parameter.type else 'mixed'
            })

        returnVariables = []

        if method.return.type and method.return.type != 'void'
            returnVariables = [method.return]

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine)

        docblock = @docblockBuilder.build(
            method.name,
            parameters,
            returnVariables,
            true,
            false,
            editor.getTabText().repeat(indentationLevel),
            true
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)
