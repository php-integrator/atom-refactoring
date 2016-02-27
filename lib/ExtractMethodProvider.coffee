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

        # Checking if a selection has been made
        if selectedBufferRange.start.row == selectedBufferRange.end.row &&
        selectedBufferRange.start.column == selectedBufferRange.end.column
            atom.notifications.addWarning(
                'You must select some text to extract',
                {
                    detail: 'PHP Integrator Refactoring'
                    dismissable: true
                }
            )
            return

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
        reducedHighlightedText = highlightedText.replace(findMultipleTab, "#{tabText}")

        @builder.setMethodBody(reducedHighlightedText)
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

        selectedBufferRange = activeTextEditor.getSelectedBufferRange()

        highlightedBufferPosition = selectedBufferRange.end
        row = 0
        loop
            row++
            descriptions = activeTextEditor.scopeDescriptorForBufferPosition(
                [highlightedBufferPosition.row + row, activeTextEditor.getTabLength()]
            )
            indexOfDescriptor = descriptions.scopes.indexOf('punctuation.section.scope.end.php')
            break if indexOfDescriptor > -1 || row == activeTextEditor.getLineCount()

        row = highlightedBufferPosition.row + row

        line = activeTextEditor.lineTextForBufferRow row

        endOfLine = line?.length

        replaceRange = [
            [row, 0],
            [row, endOfLine]
        ]

        previousText = activeTextEditor.getTextInBufferRange replaceRange

        settings.tabs = true
        newMethodBody =  @builder.buildMethod(settings)

        @builder.cleanUp()

        activeTextEditor.transact () =>
            extendedRange = @builder.selectedBufferRange
            activeTextEditor.setSelectedBufferRange extendedRange

            # Matching current indentation
            selectedText = activeTextEditor.getSelectedText()
            spacing = selectedText.match /^\s*/
            if spacing != null
                spacing = spacing[0]

            activeTextEditor.insertText(spacing + methodCall)

            # Remove any extra new lines between functions
            nextLine = activeTextEditor.lineTextForBufferRow row + 1
            if nextLine == ''
                activeTextEditor.setSelectedBufferRange(
                    [
                        [row + 1, 0],
                        [row + 1, 1]
                    ]
                )
                activeTextEditor.deleteLine()


            # Re working out range as inserting method call will delete some
            # lines and thus offsetting this
            row -= selectedBufferRange.end.row - selectedBufferRange.start.row

            replaceRange = [
                [row, 0],
                [row, line?.length]
            ]

            activeTextEditor.setTextInBufferRange(
                replaceRange,
                "#{previousText}\n\n#{newMethodBody}"
            )

    ###*
     * @inheritdoc
    ###
    getMenuItems: () ->
        return [
            {'label': 'Extract method', 'command': 'php-integrator-refactoring:extract-method'},
        ]
