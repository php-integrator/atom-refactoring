{$, TextEditorView, View} = require 'atom-space-pen-views'

Parser = require('./Builder')

module.exports =

class ExtractMethodView extends View

    ###*
     * The callback to invoke when the user confirms his selections.
    ###
    onDidConfirm  : null

    ###*
     * The callback to invoke when the user cancels the view.
    ###
    onDidCancel   : null

    ###*
     * Settings of how to generate new method that will be passed to the parser
    ###
    settings      : null

    ###*
     * Builder to use when generating preview area
    ###
    builder       : null

    ###*
     * Constructor.
     *
     * @param {Callback} onDidConfirm
     * @param {Callback} onDidCancel
    ###
    constructor: (@onDidConfirm, @onDidCancel = null) ->
        super()

        @settings = {
            generateDocs: false,
            methodName: '',
            visibility: 'public',
            tabs: false
        }

    @content: ->
        @div class: 'php-integrator-refactoring-extract-method', =>
            @div outlet: 'methodNameForm', =>
                @subview 'methodNameEditor', new TextEditorView(mini:true, placeholderText: 'Enter a method name')
                @div class: 'settings-view', =>
                    @div class: 'section-body', =>
                        @div class: 'control-group', =>
                            @div class: 'controls', =>
                                @label class: 'control-label', =>
                                    @div class: 'setting-title', 'Access Modifier'
                                    @select outlet: 'accessMethodsInput', class: 'form-control', =>
                                        @option value: 'public', 'Public'
                                        @option value: 'protected', 'Protected'
                                        @option value: 'private', 'Private'
                        @div class: 'control-group', =>
                            @div class: 'controls', =>
                                @div class: 'checkbox', =>
                                    @label =>
                                        @input outlet: 'generateDocInput', type: 'checkbox'
                                        @div class: 'setting-title', 'Generate documentation'
                        @div class: 'control-group', =>
                            @div class: 'controls', =>
                                @label class: 'control-label', =>
                                    @div class: 'setting-title', 'Preview'
                                    @pre class: 'preview-area', outlet: 'previewArea'
            @div outlet: 'buttonGroup', class: 'block pull-right', =>
                @button class: 'inline-block btn btn-success button--confirm', 'Extract method'
                @button class: 'inline-block btn button--cancel', 'Cancel'

    initialize: ->
        atom.commands.add @element,
            'core:confirm': (event) =>
                @confirm()
                event.stopPropagation()
            'core:cancel': (event) =>
                @cancel()
                event.stopPropagation()

        @on 'click', 'button', (event) =>
            @confirm()  if $(event.target).hasClass('button--confirm')
            @cancel()   if $(event.target).hasClass('button--cancel')

        @methodNameEditor.getModel().onDidChange () =>
            @settings.methodName = @methodNameEditor.getText()
            @refreshPreviewArea()

        $(@accessMethodsInput[0]).change (event) =>
            @settings.visibility = $(event.target).val()
            @refreshPreviewArea()

        $(@generateDocInput[0]).change (event) =>
            @settings.generateDocs = !@settings.generateDocs
            @refreshPreviewArea()

        @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

    ###*
     * Destroys the view and cleans up.
    ###
    destroy: ->
        @panel.destroy()
        @panel = null

    present: ->
        @panel.show()
        @methodNameEditor.focus()
        @refreshPreviewArea()

    hide: ->
        @panel.hide()
        @restoreFocus()
        @methodNameEditor.setText('')

    confirm: ->
        if @onDidConfirm
            @onDidConfirm(@getSettings())

        @hide()

    cancel: ->
        if @onDidCancel
            @onDidCancel()

        @hide()

    refreshPreviewArea: ->
        methodBody = @builder.buildMethod(@getSettings())
        $(@previewArea).text(methodBody)

    storeFocusedElement: ->
        @previouslyFocusedElement = $(document.activeElement)

    restoreFocus: ->
        @previouslyFocusedElement?.focus()

    setBuilder: (builder) ->
        @builder = builder

    ###*
     * Gets the settings currently set
     *
     * @return {Object}
    ###
    getSettings: ->
        return @settings
