{$, $$, SelectListView} = require 'atom-space-pen-views'

MultiSelectionView = require '../Utility/MultiSelectionView.coffee'

module.exports =

##*
# An extension on SelectListView from atom-space-pen-views that allows multiple selections.
##
class View extends MultiSelectionView
    ###*
     * Whether or not to make use of PHP 7 features.
    ###
    enablePhp7Support : false

    ###*
     * @inheritdoc
    ###
    createWidgets: () ->
        checkboxBar = $$ ->
            @div class: 'checkbox-bar settings-view', =>
                @div class: 'controls', =>
                    @div class: 'block text-line', =>
                        @label class: 'icon icon-info', 'Tip: The order in which items are selected determines the order of the output.'
                    @div class: 'checkbox', =>
                        @label class: 'checkbox-label', =>
                            @input type: 'checkbox', class: 'checkbox-input checkbox--enable-php7'
                            @div   class: 'setting-title checkbox-label-text', 'Enable PHP 7 support'

        checkboxBar.appendTo(this)

        $('.checkbox--enable-php7').change () =>
            @enablePhp7Support = not @enablePhp7Support

        # Ensure that button clicks are actually handled.
        @on 'mousedown', ({target}) =>
            return false if $(target).hasClass('checkbox-input')
            return false if $(target).hasClass('checkbox-label-text')

        super()

    ###*
     * @inheritdoc
    ###
    invokeOnDidConfirm: () ->
        if @onDidConfirm
           @onDidConfirm(@selectedItems, @enablePhp7Support, @getMetadata())
