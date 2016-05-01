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
        }, {
            grammarScopes: ['variable.other.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                propertyNameRange = textEditor.bufferRangeForScopeAtCursor('variable.other.php')
                propertyName = textEditor.getTextInBufferRange(propertyNameRange)

                return [
                    {
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generatePropertyDocblock(textEditor, bufferPosition, propertyName)
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
     * @param {string}     className
    ###
    generateClassLikeDocblock: (editor, triggerPosition, className) ->
        classInfo = {
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

        docblock = @docblockBuilder.buildByLines(
            [],
            editor.getTabText().repeat(indentationLevel)
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)

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

                    methodData = classInfo.methods[functionName]

                    return if not methodData

                    zeroBasedStartLine = methodData.startLine - 1

                    @generateFunctionLikeDocblockFor(editor, methodData)

                @service.getClassInfo(currentClassName).then(nestedSuccessHandler, nestedFailureHandler)

            else
                nestedSuccessHandler = (globalFunctions) =>
                    return if not functionName of globalFunctions

                    functionData = globalFunctions[functionName]

                    return if not functionData

                    zeroBasedStartLine = functionData.startLine - 1

                    @generateFunctionLikeDocblockFor(editor, functionData)

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

        docblock = @docblockBuilder.buildForMethod(
            parameters,
            methodData.return.type,
            false,
            editor.getTabText().repeat(indentationLevel)
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)

    ###*
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
     * @param {string}     propertyName
    ###
    generatePropertyDocblock: (editor, triggerPosition, propertyName) ->
        successHandler = (currentClassName) =>
            return if not currentClassName

            nestedSuccessHandler = (classInfo) =>
                propertyName = propertyName.substr(1)

                return if not propertyName of classInfo.properties

                property = classInfo.properties[propertyName]

                return if not property

                zeroBasedStartLine = property.startLine - 1

                @generatePropertyDocblockFor(editor, property)

            nestedFailureHandler = () =>
                return

            @service.getClassInfo(currentClassName).then(nestedSuccessHandler, nestedFailureHandler)

        failureHandler = () =>
            return

        @service.determineCurrentClassName(editor, triggerPosition).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     propertyData
    ###
    generatePropertyDocblockFor: (editor, propertyData) ->
        zeroBasedStartLine = propertyData.startLine - 1

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine)

        docblock = @docblockBuilder.buildForProperty(
            if propertyData.return.type then propertyData.return.type else 'mixed',
            false,
            editor.getTabText().repeat(indentationLevel)
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)
