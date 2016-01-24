{$, $$, SelectListView} = require 'atom-space-pen-views'

module.exports =

##*
# The view that allows the user to select the properties to generate for.
##
class SelectionView extends SelectListView
    onDidConfirm: null
    onDidCancel: null
    emptyMessage: null
    selectedItems: null

    constructor: (@onDidConfirm, @onDidCancel = null, @emptyMessage) ->
        super()

        @selectedItems = []

    initialize: ->
        super()

        @addClass('from-top')
        @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

        @createButtons()

        # Ensure that button clicks are actually handled.
        @on 'mousedown', ({target}) =>
            return false if $(target).hasClass('btn')


    createButtons: () ->
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

    getFilterKey: () ->
        return 'name'

    getCancelButtonText: () ->
        return 'Cancel'

    getConfirmButtonText: () ->
        return 'Generate'



    getEmptyMessage: () ->
        if @emptyMessage?
            return @emptyMessage

        return super()

    setEmptyMessage: (emptyMessage) ->
        @emptyMessage = emptyMessage

    setItems: (items) ->
        i = 0

        for item in items
            item.index = i++

        super(items)

        @selectedItems = []

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

    confirmedByButton: () ->
        if @onDidConfirm
           @onDidConfirm(@selectedItems)

        @restoreFocus()
        @panel.hide()

    cancelled: () ->
        if @onDidCancel
            @onDidCancel()

        @restoreFocus()
        @panel.hide()

    present: () ->
        @panel.show()
        @focusFilterEditor()
