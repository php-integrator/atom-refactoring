{$, $$, SelectListView} = require 'atom-space-pen-views'

module.exports =

##*
# An extension on SelectListView from atom-space-pen-views that allows multiple selections.
##
class MultiSelectionView extends SelectListView
    ###*
     * The callback to invoke when the user confirms his selections.
    ###
    onDidConfirm  : null

    ###*
     * The callback to invoke when the user cancels the view.
    ###
    onDidCancel   : null

    ###*
     * Metadata to pass to the callbacks.
    ###
    metadata      : null

    ###*
     * The message to display when there are no results.
    ###
    emptyMessage  : null

    ###*
     * Items that are currently selected.
    ###
    selectedItems : null

    ###*
     * Constructor.
     *
     * @param {Callback} onDidConfirm
     * @param {Callback} onDidCancel
    ###
    constructor: (@onDidConfirm, @onDidCancel = null) ->
        super()

        @selectedItems = []

    ###*
     * @inheritdoc
    ###
    initialize: ->
        super()

        @addClass('from-top')
        @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

        @createButtonBar()

        # Ensure that button clicks are actually handled.
        @on 'mousedown', ({target}) =>
            return false if $(target).hasClass('btn')

    ###*
     * Creates the button bar at the bottom of the view.
    ###
    createButtonBar: () ->
        cancelButtonText = @getCancelButtonText()
        confirmButtonText = @getConfirmButtonText()

        buttonBar = $$ ->
            @div class: 'php-integrator-refactoring-list-buttons', =>
                @span class: 'pull-left', =>
                    @button class: 'btn btn-error inline-block-tight icon icon-circle-slash button--cancel', cancelButtonText

                @span class: 'pull-right', =>
                    @button class: 'btn btn-success inline-block-tight icon icon-gear button--confirm', confirmButtonText

        buttonBar.appendTo(this)

        @on 'click', 'button', (event) =>
            @confirmedByButton() if $(event.target).hasClass('button--confirm')
            @cancel()            if $(event.target).hasClass('button--cancel')

        # TODO: See if we can attach a className to the list in its entiretly and use subclasses instead.
        # TODO: Split this off into a MultiSelectionView base class.

    ###*
     * @inheritdoc
    ###
    viewForItem: (item) ->
        classes = ['php-integrator-refactoring-list-item']

        if item.className
            classes.push(item.className)

        className = classes.join(' ')

        displayText = item.name
        symbolClass = if item.isSelected then 'icon icon-check' else ''

        return """
            <li class="#{className}">
                <span class="symbol #{symbolClass}"></span>
                <span class="display-text">#{displayText}</span>
            </li>
        """

    ###*
     * @inheritdoc
    ###
    getFilterKey: () ->
        return 'name'

    ###*
     * Retrieves the text to display on the cancel button.
     *
     * @return {string}
    ###
    getCancelButtonText: () ->
        return 'Cancel'

    ###*
     * Retrieves the text to display on the confirmation button.
     *
     * @return {string}
    ###
    getConfirmButtonText: () ->
        return 'Generate'

    ###*
     * Retrieves the message that is displayed when there are no results.
     *
     * @return {string}
    ###
    getEmptyMessage: () ->
        if @emptyMessage?
            return @emptyMessage

        return super()

    ###*
     * Sets the message that is displayed when there are no results.
     *
     * @param {string} emptyMessage
    ###
    setEmptyMessage: (emptyMessage) ->
        @emptyMessage = emptyMessage

    ###*
     * Retrieves the metadata to pass to the callbacks.
     *
     * @return {Object|null}
    ###
    getMetadata: () ->
        return @metadata

    ###*
     * Sets the metadata to pass to the callbacks.
     *
     * @param {Object|null} metadata
    ###
    setMetadata: (metadata) ->
        @metadata = metadata

    ###*
     * @inheritdoc
    ###
    setItems: (items) ->
        i = 0

        for item in items
            item.index = i++

        super(items)

        @selectedItems = []

    ###*
     * @inheritdoc
    ###
    confirmed: (item) ->
        item.isSelected = not item.isSelected

        if item.isSelected
            @selectedItems.push(item)

        else
            index = @selectedItems.indexOf(item)

            if index >= 0
                @selectedItems.splice(index, 1)

        selectedItem = @getSelectedItem()
        index = if selectedItem then selectedItem.index else 0

        @populateList()

        @selectItemView(@list.find("li:nth(#{index})"))

    ###*
     * Invoked when the user confirms his selections by pressing the confirmation button.
    ###
    confirmedByButton: () ->
        if @onDidConfirm
           @onDidConfirm(@selectedItems, @getMetadata())

        @restoreFocus()
        @panel.hide()

    ###*
     * @inheritdoc
    ###
    cancelled: () ->
        if @onDidCancel
            @onDidCancel(@getMetadata())

        @restoreFocus()
        @panel.hide()

    ###*
     * Presents the view to the user.
    ###
    present: () ->
        @panel.show()
        @focusFilterEditor()
