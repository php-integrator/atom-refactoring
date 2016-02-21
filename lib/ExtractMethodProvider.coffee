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
    ###
    extractMethodView: null

    builder: null

    ###*
     * @inheritdoc
    ###
    activate: (service) ->
        super(service)

        @extractMethodView = new View(@onConfirm.bind(this))
        @builder = new Builder()

        @builder.setService(service)
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

    onConfirm: (settings) ->
        methodCall = @builder.buildMethodCall(
            settings.methodName
        )
        activeTextEditor = atom.workspace.getActiveTextEditor()

        activeTextEditor.insertText(methodCall)

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
            [highlightedBufferPosition.row + row, activeTextEditor.getTabLength()],
            [highlightedBufferPosition.row + row, Infinity]
        ]
        previousText  = activeTextEditor.getTextInBufferRange(replaceRange)

        settings.tabs = true
        newMethodBody =  @builder.buildMethod(settings)

        @builder.cleanUp()

        activeTextEditor.setTextInBufferRange(
            replaceRange,
            "#{previousText}\n\n#{newMethodBody}\n"
        )
