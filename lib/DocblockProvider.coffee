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
                nameRange = textEditor.bufferRangeForScopeAtCursor('entity.name.type')

                return if not nameRange?

                name = textEditor.getTextInBufferRange(nameRange)

                return @getClasslikeIntentions(textEditor, bufferPosition, name)
        }, {
            grammarScopes: ['entity.name.function.php', 'support.function.magic.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                nameRange = textEditor.bufferRangeForScopeAtCursor('entity.name.function.php')

                if not nameRange?
                    nameRange = textEditor.bufferRangeForScopeAtCursor('support.function.magic.php')

                return if not nameRange?

                name = textEditor.getTextInBufferRange(nameRange)

                return @getFunctionlikeIntentions(textEditor, bufferPosition, name)
        }, {
            grammarScopes: ['variable.other.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                nameRange = textEditor.bufferRangeForScopeAtCursor('variable.other.php')

                return if not nameRange?

                name = textEditor.getTextInBufferRange(nameRange)

                return @getPropertyIntentions(textEditor, bufferPosition, name)
        }, {
            grammarScopes: ['constant.other.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                nameRange = textEditor.bufferRangeForScopeAtCursor('constant.other.php')

                return if not nameRange?

                name = textEditor.getTextInBufferRange(nameRange)

                return [
                    {
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generateConstantDocblock(textEditor, bufferPosition, name)
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
     * @param {String}     name
    ###
    getClasslikeIntentions: (editor, triggerPosition, name) ->
        failureHandler = () ->
            return []

        successHandler = (resolvedType) =>
            nestedSuccessHandler = (classInfo) =>
                intentions = []

                return intentions if not classInfo?

                if not classInfo.hasDocblock
                    if classInfo.hasDocumentation
                        intentions.push({
                            priority : 100
                            icon     : 'gear'
                            title    : 'Generate Docblock (inheritDoc)'

                            selected : () =>
                                @generateDocblockInheritance(editor, triggerPosition)
                        })

                    intentions.push({
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generateClasslikeDocblockFor(editor, classInfo)
                    })

                return intentions

            return @service.getClassInfo(resolvedType).then(nestedSuccessHandler, failureHandler)

        return @service.resolveType(editor.getPath(), triggerPosition.row + 1, name).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     classData
    ###
    generateClasslikeDocblockFor: (editor, classData) ->
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
     * @param {String}     name
    ###
    getFunctionlikeIntentions: (editor, triggerPosition, name) ->
        failureHandler = () =>
            return []

        successHandler = (currentClassName) =>
            helperFunction = (functionlikeData) =>
                intentions = []

                return intentions if not functionlikeData

                if not functionlikeData.hasDocblock
                    if functionlikeData.hasDocumentation
                        intentions.push({
                            priority : 100
                            icon     : 'gear'
                            title    : 'Generate Docblock (inheritDoc)'

                            selected : () =>
                                @generateDocblockInheritance(editor, triggerPosition)
                        })

                    intentions.push({
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generateFunctionlikeDocblockFor(editor, functionlikeData)
                    })

                return intentions

            if currentClassName
                nestedSuccessHandler = (classInfo) =>
                    return [] if not name of classInfo.methods
                    return helperFunction(classInfo.methods[name])

                @service.getClassInfo(currentClassName).then(nestedSuccessHandler, failureHandler)

            else
                nestedSuccessHandler = (globalFunctions) =>
                    return [] if not name of globalFunctions
                    return helperFunction(globalFunctions[name])

                @service.getGlobalFunctions().then(nestedSuccessHandler, failureHandler)

        @service.determineCurrentClassName(editor, triggerPosition).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     data
    ###
    generateFunctionlikeDocblockFor: (editor, data) ->
        zeroBasedStartLine = data.startLine - 1

        parameters = []

        for parameter in data.parameters
            parameters.push({
                name: '$' + parameter.name
                type: if parameter.type then parameter.type else 'mixed'
            })

        returnVariables = []

        if data.return.type and data.return.type != 'void'
            returnVariables = [data.return]

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine)

        docblock = @docblockBuilder.buildForMethod(
            parameters,
            data.return.type,
            false,
            editor.getTabText().repeat(indentationLevel)
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)

    ###*
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
     * @param {String}     name
    ###
    getPropertyIntentions: (editor, triggerPosition, name) ->
        failureHandler = () =>
            return []

        successHandler = (currentClassName) =>
            return [] if not currentClassName?

            nestedSuccessHandler = (classInfo) =>
                name = name.substr(1)

                return [] if not name of classInfo.properties

                propertyData = classInfo.properties[name]

                return if not propertyData?

                intentions = []

                return intentions if not propertyData

                if not propertyData.hasDocblock
                    if propertyData.hasDocumentation
                        intentions.push({
                            priority : 100
                            icon     : 'gear'
                            title    : 'Generate Docblock (inheritDoc)'

                            selected : () =>
                                @generateDocblockInheritance(editor, triggerPosition)
                        })

                    intentions.push({
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generatePropertyDocblockFor(editor, propertyData)
                    })

                return intentions

            @service.getClassInfo(currentClassName).then(nestedSuccessHandler, failureHandler)

        @service.determineCurrentClassName(editor, triggerPosition).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     data
    ###
    generatePropertyDocblockFor: (editor, data) ->
        zeroBasedStartLine = data.startLine - 1

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine)

        docblock = @docblockBuilder.buildForProperty(
            if data.return.type then data.return.type else 'mixed',
            false,
            editor.getTabText().repeat(indentationLevel)
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)

    ###*
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
     * @param {string}     constantName
    ###
    generateConstantDocblock: (editor, triggerPosition, constantName) ->
        successHandler = (currentClassName) =>
            nestedFailureHandler = () =>
                return

            if currentClassName
                nestedSuccessHandler = (classInfo) =>
                    return if not constantName of classInfo.constants

                    methodData = classInfo.constants[constantName]

                    return if not methodData

                    zeroBasedStartLine = methodData.startLine - 1

                    @generateConstantDocblockFor(editor, methodData)

                @service.getClassInfo(currentClassName).then(nestedSuccessHandler, nestedFailureHandler)

            else
                nestedSuccessHandler = (globalConstants) =>
                    return if not constantName of globalConstants

                    functionData = globalConstants[constantName]

                    return if not functionData

                    zeroBasedStartLine = functionData.startLine - 1

                    @generateConstantDocblockFor(editor, functionData)

                @service.getGlobalConstants().then(nestedSuccessHandler, nestedFailureHandler)

        failureHandler = () =>
            return

        @service.determineCurrentClassName(editor, triggerPosition).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     data
    ###
    generateConstantDocblockFor: (editor, data) ->
        zeroBasedStartLine = data.startLine - 1

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine)

        docblock = @docblockBuilder.buildForProperty(
            if data.return.type then data.return.type else 'mixed',
            false,
            editor.getTabText().repeat(indentationLevel)
        )

        editor.getBuffer().insert(new Point(zeroBasedStartLine, -1), docblock)

    ###*
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
    ###
    generateDocblockInheritance: (editor, triggerPosition) ->
        indentationLevel = editor.indentationForBufferRow(triggerPosition.row)

        docblock = @docblockBuilder.buildByLines(
            ['@inheritDoc'],
            editor.getTabText().repeat(indentationLevel)
        )

        editor.getBuffer().insert(new Point(triggerPosition.row, -1), docblock)
