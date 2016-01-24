AbstractProvider = require './AbstractProvider'

MultiSelectionView = require './Utility/MultiSelectionView'

module.exports =

##*
# Provides getter and setter (accessor and mutator) generation capabilities.
##
class GetterSetterProvider extends AbstractProvider
    ###*
     * The view that allows the user to select the properties to generate for.
    ###
    selectionView: null

    ###*
     * The disposable that can be used to remove the menu items again.
    ###
    menuItemDisposable: null

    ###*
     * @inheritdoc
    ###
    activate: (service) ->
        super(service)

        @selectionView = new MultiSelectionView(@onConfirm.bind(this), @onCancel.bind(this))
        @selectionView.setLoading('Loading class information...')
        @selectionView.setEmptyMessage('No properties found.')

        atom.commands.add 'atom-workspace', "php-integrator-refactoring:generate-getter": =>
            @executeCommand(true, false)

        atom.commands.add 'atom-workspace', "php-integrator-refactoring:generate-setter": =>
            @executeCommand(false, true)

        atom.commands.add 'atom-workspace', "php-integrator-refactoring:generate-getter-setter-pair": =>
            @executeCommand(true, true)

        # TODO: The base menu should always be the same, add to base class.
        # TODO: The menu ordering is not ideal.
        # TODO: Add docblocks everywhere.

        @menuItemDisposable = atom.menu.add([
            {
                'label': 'Packages'
                'submenu': [
                    {
                        'label': 'PHP Integrator',
                        'submenu': [
                            {
                                'label': 'Refactoring'
                                'submenu': [
                                    {'label': 'Generate Getter(s)', 'command': 'php-integrator-refactoring:generate-getter'},
                                    {'label': 'Generate Setter(s)', 'command': 'php-integrator-refactoring:generate-setter'},
                                    {'label': 'Generate Getter And Setter Pair(s)', 'command': 'php-integrator-refactoring:generate-getter-setter-pair'},
                                ]
                            }
                        ]
                    }
                ]
            }
        ])

    ###*
     * @inheritdoc
    ###
    deactivate: () ->
        @super()

        @selectionView.destroy()
        @selectionView = null

        @menuItemDisposable.dispose()
        @menuItemDisposable = null

        # TODO: Test package deactivation, something is still going wrong with the selectionView being null after
        # reactivation.

    executeCommand: (enableGetterGeneration, enableSetterGeneration) ->
        activeTextEditor = atom.workspace.getActiveTextEditor()

        return if not activeTextEditor

        @selectionView.setMetadata({editor: activeTextEditor, enablePhp7Features: false})
        @selectionView.storeFocusedElement()
        @selectionView.present()

        currentClassName = @service.determineFullClassName(activeTextEditor)

        @service.getClassInfo(currentClassName, true).then (classInfo) =>
            enabledItems = []
            disabledItems = []

            for name, property of classInfo.properties
                isClassType = false
                enablePhp7Features = false

                # TODO: Fill in enableTypeHintGeneration based on if it's a class type or not. If enablePhp7Features
                # is true, this can always be true.

                getterName = 'get' + name.substr(0, 1).toUpperCase() + name.substr(1)
                setterName = 'set' + name.substr(0, 1).toUpperCase() + name.substr(1)

                getterExists = if getterName of classInfo.methods then true else false
                setterExists = if setterName of classInfo.methods then true else false

                data = {
                    name                     : name
                    type                     : if property.return.type then property.return.resolvedType else 'mixed'
                    needsGetter              : enableGetterGeneration
                    needsSetter              : enableSetterGeneration
                    getterName               : getterName
                    setterName               : setterName
                    enablePhp7Features       : enablePhp7Features
                    enableTypeHintGeneration : enablePhp7Features or isClassType # NOTE: Not relevant for getters.
                }

                if (enableGetterGeneration and enableSetterGeneration and getterExists and setterExists) or
                   (enableGetterGeneration and getterExists) or
                   (enableSetterGeneration and setterExists)
                    data.className = 'php-integrator-refactoring-strikethrough'
                    disabledItems.push(data)

                else
                    data.className = ''
                    enabledItems.push(data)

            # Sort alphabetically and put the disabled items at the end.
            sorter = (a, b) ->
                return a.name.localeCompare(b.name)

            enabledItems.sort(sorter)
            disabledItems.sort(sorter)

            @selectionView.setItems(enabledItems.concat(disabledItems))

            # TODO: We should actually be adding an 'unresolved' type. The 'type' is already partially resolved due
            #       to the base package's NameResolver (node visitor).

    onCancel: (metadata) ->

    onConfirm: (selectedItems, metadata) ->
        # TODO: Only generate type hints for class properties (optionally add a checkbox to the selection view
        # to specify whether the user wants type hints for basic types as well if he using PHP 7).

        itemOutputs = []

        for item in selectedItems
            if item.needsGetter
                itemOutputs.push(@generateGetterForItem(item))

            if item.needsSetter
                itemOutputs.push(@generateSetterForItem(item))

        output = itemOutputs.join("\n\n").trim()

        metadata.editor.insertText(output, {
            autoIndent         : true
            autoIndentNewline  : true
            autoDecreaseIndent : true
        })

        # FIXME: Atom doesn't seem to want to auto indent the added text. If select: true is passed during insertion
        # and this method invoked, it works, but we don't want to alter the user's selection (or have to restore it
        # just because functionality that should be working fails).
        #metadata.editor.autoIndentSelectedRows()

    generateGetterForItem: (item) ->
        returnTypeDeclaration = ''

        if item.enablePhp7Features
            returnTypeDeclaration = ': ' + item.type

        return """
            /**
             * Retrieves the currently set #{item.name}.
             *
             * @return #{item.type}
             */
            public function #{item.getterName}()#{returnTypeDeclaration}
            {
                return $this->#{item.name};
            }
        """

    generateSetterForItem: (item) ->
        typePrefix = ''

        if item.enableTypeHintGeneration
            typePrefix = item.type + ' '

        returnTypeDeclaration = ''

        if item.enablePhp7Features
            returnTypeDeclaration = ': self'

        return """
            /**
             * Sets the #{item.name} to use.
             *
             * @param #{item.type} $value
             *
             * @return $this
             */
            public function #{item.setterName}(#{typePrefix}$value)#{returnTypeDeclaration}
            {
                $this->#{item.name} = $value;
                return $this;
            }
        """
