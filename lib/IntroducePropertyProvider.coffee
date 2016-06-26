{Point} = require 'atom'

AbstractProvider = require './AbstractProvider'

DocblockBuilder = require './Utility/DocblockBuilder'

module.exports =

##*
# Provides property generation for non-existent properties.
##
class IntroducePropertyProvider extends AbstractProvider
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
    deactivate: () ->
        super()

        if @docblockBuilder
            #@docblockBuilder.destroy()
            @docblockBuilder = null

    ###*
     * @inheritdoc
    ###
    getIntentionProviders: () ->
        return [{
            grammarScopes: ['variable.other.property.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                nameRange = textEditor.bufferRangeForScopeAtCursor('variable.other.property')

                return if not nameRange?

                name = textEditor.getTextInBufferRange(nameRange)

                return @getIntentions(textEditor, bufferPosition, name)
        }]

    ###*
     * @param {TextEditor} editor
     * @param {Point}      triggerPosition
     * @param {String}     name
    ###
    getIntentions: (editor, triggerPosition, name) ->
        failureHandler = () =>
            return []

        successHandler = (currentClassName) =>
            return [] if not currentClassName?

            nestedSuccessHandler = (classInfo) =>
                intentions = []

                return intentions if not classInfo

                if name not of classInfo.properties
                    intentions.push({
                        priority : 100
                        icon     : 'gear'
                        title    : 'Introduce New Property'

                        selected : () =>
                            @introducePropertyFor(editor, classInfo, name)
                    })

                return intentions

            @service.getClassInfo(currentClassName).then(nestedSuccessHandler, failureHandler)

        @service.determineCurrentClassName(editor, triggerPosition).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     classData
     * @param {String}     name
    ###
    introducePropertyFor: (editor, classData, name) ->
        zeroBasedStartLine = classData.startLine - 1
        startLine = zeroBasedStartLine + 2

        indentationLevel = editor.indentationForBufferRow(zeroBasedStartLine) + 1

        tabText = editor.getTabText().repeat(indentationLevel)

        docblock = @docblockBuilder.buildForProperty(
            'mixed',
            false,
            tabText
        )

        property = "#{tabText}protected $#{name};\n\n"

        editor.getBuffer().insert(new Point(startLine, -1), docblock + property)
