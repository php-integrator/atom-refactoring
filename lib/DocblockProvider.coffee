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

        atom.commands.add 'atom-workspace', "php-integrator-refactoring:generate-docblock": =>
            @generateDocblock()

    ###*
     * @inheritdoc
    ###
    getIntentionProviders: () ->
        return [{
            grammarScopes: ['meta.function.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                return [
                    {
                        priority : 100
                        icon     : 'gear'
                        title    : 'Generate Docblock'

                        selected : () =>
                            @generateDocblock()
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
    ###
    generateDocblock: () ->
        activeTextEditor = atom.workspace.getActiveTextEditor()

        return if not activeTextEditor

        currentBufferPosition = activeTextEditor.getCursorBufferPosition()

        currentLine = currentBufferPosition.row

        successHandler = (currentClassName) =>
            return if not currentClassName

            nestedSuccessHandler = (classInfo) =>
                enabledItems = []
                disabledItems = []

                for name, method of classInfo.methods
                    zeroBasedStartLine = method.startLine - 1

                    if zeroBasedStartLine == currentLine
                        parameters = []

                        for parameter in method.parameters
                            parameters.push({
                                name: '$' + parameter.name
                                type: if parameter.type then parameter.type else 'mixed'
                            })

                        returnVariables = if method.return.type? then [method.return] else []

                        docblock = @docblockBuilder.build(
                            name,
                            parameters,
                            returnVariables,
                            true,
                            false,
                            activeTextEditor.getTabText(),
                            true
                        )

                        activeTextEditor.getBuffer().insert(new Point(currentLine, -1), docblock)

                        break

            nestedFailureHandler = () =>
                return

            @service.getClassInfo(currentClassName).then(nestedSuccessHandler, nestedFailureHandler)

        failureHandler = () =>
            return

        @service.determineCurrentClassName(activeTextEditor, activeTextEditor.getCursorBufferPosition()).then(successHandler, failureHandler)
