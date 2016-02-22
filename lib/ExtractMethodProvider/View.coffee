{$, TextEditorView, View} = require 'atom-space-pen-views'

Parser = require('./Builder')

module.exports =

class ExtractMethodView extends View

    ###*
     * The callback to invoke when the user confirms his selections.
     *
     * @type {Callback}
    ###
    onDidConfirm  : null

    ###*
     * The callback to invoke when the user cancels the view.
     *
     * @type {Callback}
    ###
    onDidCancel   : null

    ###*
     * Settings of how to generate new method that will be passed to the parser
     *
     * @type {Object}
    ###
    settings      : null

    ###*
     * Builder to use when generating preview area
     *
     * @type {Builder}
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
            tabs: false,
            arraySyntax: 'word'
        }

    ###*
     * Content to be displayed when this view is shown.
    ###
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
                        @div class: 'return-multiple-control control-group hide', =>
                            @div class: 'controls', =>
                                @div class: 'checkbox', =>
                                    @label =>
                                        @input outlet: 'arraySyntax', type: 'checkbox'
                                        @div class: 'setting-title', 'Use PHP 5.4+ array syntax (Square brackets)'
                        @div class: 'control-group', =>
                            @div class: 'controls', =>
                                @label class: 'control-label', =>
                                    @div class: 'setting-title', 'Preview'
                                    @pre class: 'preview-area', outlet: 'previewArea'
            @div outlet: 'buttonGroup', class: 'block pull-right', =>
                @button class: 'inline-block btn btn-success button--confirm', 'Extract method'
                @button class: 'inline-block btn button--cancel', 'Cancel'

    ###*
     * @inheritdoc
    ###
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

        $(@arraySyntax[0]).change (event) =>
            if @settings.arraySyntax == 'word'
                @settings.arraySyntax = 'brackets'
            else
                @settings.arraySyntax = 'word'
            @refreshPreviewArea()

        @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

    ###*
     * Destroys the view and cleans up.
    ###
    destroy: ->
        @panel.destroy()
        @panel = null

    ###*
    * Shows the view and refreshes the preview area with the current settings.
    ###
    present: ->
        @panel.show()
        @methodNameEditor.focus()
        @methodNameEditor.setText('')

    ###*
     * Hides the panel.
    ###
    hide: ->
        @panel.hide()
        @restoreFocus()

    ###*
     * Called when the user confirms the extraction and will then call
     * onDidConfirm, if set.
    ###
    confirm: ->
        if @onDidConfirm
            @onDidConfirm(@getSettings())

        @hide()

    ###*
     * Called when the user cancels the extraction and will then call
     * onDidCancel, if set.
    ###
    cancel: ->
        if @onDidCancel
            @onDidCancel()

        @hide()

    ###*
     * Updates the preview area using the current setttings.
    ###
    refreshPreviewArea: ->
        methodBody = @builder.buildMethod(@getSettings())
        if @builder.hasReturnValues()
            if @builder.hasMultipleReturnValues()
                $('.php-integrator-refactoring-extract-method .return-multiple-control').removeClass('hide')

            $('.php-integrator-refactoring-extract-method .return-control').removeClass('hide')
        else
            $('.php-integrator-refactoring-extract-method .return-control').addClass('hide')
            $('.php-integrator-refactoring-extract-method .return-multiple-control').addClass('hide')

        $(@previewArea).text(methodBody)

    ###*
     * Stores the currently focused element so it can be returned focus after
     * this panel is hidden.
    ###
    storeFocusedElement: ->
        @previouslyFocusedElement = $(document.activeElement)

    ###*
     * Restores focus back to the element that was focused before this panel
     * was shown.
    ###
    restoreFocus: ->
        @previouslyFocusedElement?.focus()

    ###*
     * Sets the builder to use when generating the preview area.
     *
     * @param {Builder} builder
    ###
    setBuilder: (builder) ->
        @builder = builder

    ###*
     * Gets the settings currently set
     *
     * @return {Object}
    ###
    getSettings: ->
        return @settings
