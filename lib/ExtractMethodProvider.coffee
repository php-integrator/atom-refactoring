{Range} = require 'atom'

AbstractProvider = require './AbstractProvider'

View = require './ExtractMethodProvider/View'
Builder = require './ExtractMethodProvider/Builder'

module.exports =

##*
# Provides method extraction capabilities.
##
class ExtractMethodProvider extends AbstractProvider

    ###*
     * View that the user interacts with when extracting code.
     *
     * @type {View}
    ###
    extractMethodView: null

    ###*
     * Builder used to generate the new method.
     *
     * @type {Builder}
    ###
    builder: null

    ###*
     * @inheritdoc
    ###
    activate: (service) ->
        super(service)

        @extractMethodView = new View(@onConfirm.bind(this), @onCancel.bind(this))
        @builder = new Builder(service)

        @extractMethodView.setBuilder(@builder)

        atom.commands.add 'atom-text-editor', "php-integrator-refactoring:extract-method": =>
            @executeCommand()

    ###*
     * @inheritdoc
    ###
    deactivate: () ->
        super()

        if @extractMethodView
            @extractMethodView.destroy()
            @extractMethodView = null

    ###*
     * Executes the extraction.
    ###
    executeCommand: () ->
        activeTextEditor = atom.workspace.getActiveTextEditor()

        return if not activeTextEditor

        tabText = activeTextEditor.getTabText()

        selectedBufferRange = activeTextEditor.getSelectedBufferRange()
        extendedRange = new Range(
            [selectedBufferRange.start.row, 0],
            [selectedBufferRange.end.row, Infinity]
        )
        highlightedText = activeTextEditor.getTextInBufferRange(extendedRange)


        line = activeTextEditor.lineTextForBufferRow(selectedBufferRange.start.row)
        findSingleTab = new RegExp("(#{tabText})", "g")
        matches = (line.match(findSingleTab) || []).length

        multipleTabTexts = Array(matches).fill("#{tabText}")
        findMultipleTab = new RegExp("^" + multipleTabTexts.join(''), "mg")

        # Replacing double indents with one, so it can be shown in the preview
        # area of panel
        reducedHighligtedText = highlightedText.replace(findMultipleTab, "#{tabText}")

        @builder.setMethodBody(reducedHighligtedText)
        @builder.setEditor(activeTextEditor)
        @extractMethodView.storeFocusedElement()
        @extractMethodView.present()

    ###*
     * Called when the user has cancel the extraction in the modal.
    ###
    onCancel: ->
        @builder.cleanUp()

    ###*
     * Called when the user has confirmed the extraction in the modal.
     *
     * @param  {Object} settings
     *
     * @see ParameterParser.buildMethod for structure of settings
    ###
    onConfirm: (settings) ->
        methodCall = @builder.buildMethodCall(
            settings.methodName
        )
        activeTextEditor = atom.workspace.getActiveTextEditor()

        highlightedBufferPosition = activeTextEditor.getSelectedBufferRange().end
        row = 0
        loop
            row++
            descriptions = activeTextEditor.scopeDescriptorForBufferPosition(
                [highlightedBufferPosition.row + row, activeTextEditor.getTabLength()]
            )
            indexOfDescriptor = descriptions.scopes.indexOf('punctuation.section.scope.end.php')
            break if indexOfDescriptor == descriptions.scopes.length - 1 || row == activeTextEditor.getLineCount()

        replaceRange = [
            [highlightedBufferPosition.row + row, activeTextEditor.getTabLength() + 1],
            [highlightedBufferPosition.row + row, Infinity]
        ]

        settings.tabs = true
        newMethodBody =  @builder.buildMethod(settings)

        @builder.cleanUp()

        activeTextEditor.transact () =>
            activeTextEditor.insertText(methodCall)

            activeTextEditor.setTextInBufferRange(
                replaceRange,
                "\n#{newMethodBody}"
            )

    ###*
     * @inheritdoc
    ###
    getMenuItems: () ->
        return [
            {'label': 'Extract method', 'command': 'php-integrator-refactoring:extract-method'},
        ]
