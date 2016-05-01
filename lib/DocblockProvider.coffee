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
            grammarScopes: ['entity.name.type.class.php', 'entity.name.type.interface.php', 'entity.name.type.trait.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                classNameRange = textEditor.bufferRangeForScopeAtCursor('entity.name.type')
                className = textEditor.getTextInBufferRange(classNameRange)

                return [
                    {
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generateClassLikeDocblock(textEditor, bufferPosition, className)
                    }
                ]
        }, {
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
                            @generateFunctionLikeDocblock(textEditor, bufferPosition, functionName)
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
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
     * @param {string}     functionName
    ###
    generateFunctionLikeDocblock: (editor, triggerPosition, functionName) ->
        successHandler = (currentClassName) =>
            nestedFailureHandler = () =>
                return

            if currentClassName
                nestedSuccessHandler = (classInfo) =>
                    return if not functionName of classInfo.methods

                    method = classInfo.methods[functionName]

                    zeroBasedStartLine = method.startLine - 1

                    @generateFunctionLikeDocblockFor(editor, method)

                @service.getClassInfo(currentClassName).then(nestedSuccessHandler, nestedFailureHandler)

            else
                nestedSuccessHandler = (globalFunctions) =>
                    return if not functionName of globalFunctions

                    method = globalFunctions[functionName]

                    zeroBasedStartLine = method.startLine - 1

                    @generateFunctionLikeDocblockFor(editor, method)

                @service.getGlobalFunctions().then(nestedSuccessHandler, nestedFailureHandler)

        failureHandler = () =>
            return

        @service.determineCurrentClassName(editor, triggerPosition).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     methodData
    ###
    generateFunctionLikeDocblockFor: (editor, methodData) ->
        zeroBasedStartLine = methodData.startLine - 1

        parameters = []

        for parameter in methodData.parameters
            parameters.push({
                name: '$' + parameter.name
                type: if parameter.type then parameter.type else 'mixed'
            })

        returnVariables = []

        if methodData.return.type and methodData.return.type != 'void'
            returnVariables = [methodData.return]

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine)

        docblock = @docblockBuilder.build(
            methodData.name,
            parameters,
            returnVariables,
            true,
            false,
            editor.getTabText().repeat(indentationLevel),
            true
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)


    ###*
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
     * @param {string}     className
    ###
    generateClassLikeDocblock: (editor, triggerPosition, className) ->
        classInfo = {
            name      : className
            startLine : triggerPosition.row + 1
        }

        @generateClassLikeDocblockFor(editor, classInfo)

        # successHandler = (classInfo) =>
            # return if not classInfo

            # @generateClassLikeDocblockFor(editor, classInfo)

        # failureHandler = () =>
            # return

        # return @service.getClassListForFile(className).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     classData
    ###
    generateClassLikeDocblockFor: (editor, classData) ->
        zeroBasedStartLine = classData.startLine - 1

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine)

        docblock = @docblockBuilder.build(
            classData.name,
            [],
            [],
            true,
            false,
            editor.getTabText().repeat(indentationLevel),
            true
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)
