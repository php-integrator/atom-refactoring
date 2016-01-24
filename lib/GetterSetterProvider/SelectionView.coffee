{SelectListView} = require 'atom-space-pen-views'

module.exports =

##*
# The view that allows the user to select the properties to generate for.
##
class SelectionView extends SelectListView
    onDidConfirm: null
    onDidCancel: null

    constructor: (@onDidConfirm, @onDidCancel = null) ->
        super()

    initialize: ->
        super()

        @addClass('overlay from-top')
        @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

        # @panel.destroy()

    viewForItem: (item) ->
        "<li>#{item.name}</li>"

    getFilterKey: () ->
        return 'name'

    confirmed: (item) ->
        if @onDidConfirm
            @onDidConfirm(item)

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
