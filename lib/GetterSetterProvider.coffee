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

    ###*
     * @inheritdoc
    ###
    getMenuItems: () ->
        return [
            {'label': 'Generate Getter(s)',                 'command': 'php-integrator-refactoring:generate-getter'},
            {'label': 'Generate Setter(s)',                 'command': 'php-integrator-refactoring:generate-setter'},
            {'label': 'Generate Getter And Setter Pair(s)', 'command': 'php-integrator-refactoring:generate-getter-setter-pair'},
        ]

    ###*
     * @inheritdoc
    ###
    deactivate: () ->
        super()

        @selectionView.destroy()
        @selectionView = null

        # TODO: Test package deactivation, something is still going wrong with the selectionView being null after
        # reactivation.

    ###*
     * Executes the generation.
     *
     * @param {boolean} enableGetterGeneration
     * @param {boolean} enableSetterGeneration
    ###
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
                enablePhp7Features = false

                type = if property.return.resolvedType then property.return.resolvedType else 'mixed'
                isClassType = @isClassType(type)

                # TODO: We should actually be adding an 'unresolved' type. The 'type' is already partially resolved due
                #       to the base package's NameResolver (node visitor).
                if isClassType
                    type = '\\' + type

                getterName = 'get' + name.substr(0, 1).toUpperCase() + name.substr(1)
                setterName = 'set' + name.substr(0, 1).toUpperCase() + name.substr(1)

                getterExists = if getterName of classInfo.methods then true else false
                setterExists = if setterName of classInfo.methods then true else false

                data = {
                    name                     : name
                    type                     : type
                    needsGetter              : enableGetterGeneration
                    needsSetter              : enableSetterGeneration
                    getterName               : getterName
                    setterName               : setterName
                    enablePhp7Features       : enablePhp7Features
                    enableTypeHintGeneration : enablePhp7Features or isClassType # NOTE: Not used for getters.
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

    ###*
     * Indicates if the specified type is a class type or not.
     *
     * @return {bool}
    ###
    isClassType: (type) ->
        return if type.substr(0, 1).toUpperCase() == type.substr(0, 1) then true else false

    ###*
     * Called when the selection of properties is cancelled.
    ###
    onCancel: (metadata) ->

    ###*
     * Called when the selection of properties is confirmed.
     *
     * @param {array}       selectedItems
     * @param {Object|null} metadata
    ###
    onConfirm: (selectedItems, metadata) ->
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

    ###*
     * Generates a getter for the specified selected item.
     *
     * @param {Object} item
     *
     * @return {string}
    ###
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

    ###*
     * Generates a setter for the specified selected item.
     *
     * @param {Object} item
     *
     * @return {string}
    ###
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
             * @param #{item.type} $#{item.name}
             *
             * @return $this
             */
            public function #{item.setterName}(#{typePrefix}$#{item.name})#{returnTypeDeclaration}
            {
                $this->#{item.name} = $#{item.name};
                return $this;
            }
        """
