AbstractProvider = require './AbstractProvider'

View = require './GetterSetterProvider/View'

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

        @selectionView = new View(@onConfirm.bind(this), @onCancel.bind(this))
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
    deactivate: () ->
        super()

        if @selectionView
            @selectionView.destroy()
            @selectionView = null

    ###*
     * @inheritdoc
    ###
    getIntentionProviders: () ->
        return [{
            grammarScopes: ['source.php']
            getIntentions: ({textEditor, bufferPosition}) =>
                successHandler = (currentClassName) =>
                    return [] if not currentClassName

                    return [
                        {
                            priority : 100
                            icon     : 'gear'
                            title    : 'Generate Getter And Setter Pair(s)'

                            selected : () =>
                                @executeCommand(true, true)
                        }

                        {
                            priority : 100
                            icon     : 'gear'
                            title    : 'Generate Getter(s)'

                            selected : () =>
                                @executeCommand(true, false)
                        },

                        {
                            priority : 100
                            icon     : 'gear'
                            title    : 'Generate Setter(s)'

                            selected : () =>
                                @executeCommand(false, true)
                        }
                    ]

                failureHandler = () ->
                    return []

                activeTextEditor = atom.workspace.getActiveTextEditor()

                return [] if not activeTextEditor

                return @service.determineCurrentClassName(activeTextEditor, activeTextEditor.getCursorBufferPosition()).then(successHandler, failureHandler)
        }]

    ###*
     * Executes the generation.
     *
     * @param {boolean} enableGetterGeneration
     * @param {boolean} enableSetterGeneration
    ###
    executeCommand: (enableGetterGeneration, enableSetterGeneration) ->
        activeTextEditor = atom.workspace.getActiveTextEditor()

        return if not activeTextEditor

        @selectionView.setMetadata({editor: activeTextEditor})
        @selectionView.storeFocusedElement()
        @selectionView.present()

        successHandler = (currentClassName) =>
            return if not currentClassName

            nestedSuccessHandler = (classInfo) =>
                enabledItems = []
                disabledItems = []

                for name, property of classInfo.properties
                    type = if property.return.type then property.return.type else 'mixed'

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

            nestedFailureHandler = () =>
                @selectionView.setItems([])

            @service.getClassInfo(currentClassName).then(nestedSuccessHandler, nestedFailureHandler)

        failureHandler = () =>
            @selectionView.setItems([])

        @service.determineCurrentClassName(activeTextEditor, activeTextEditor.getCursorBufferPosition()).then(successHandler, failureHandler)

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
     * @param {boolean}     enablePhp7Support
     * @param {Object|null} metadata
    ###
    onConfirm: (selectedItems, enablePhp7Support, metadata) ->
        itemOutputs = []

        for item in selectedItems
            if item.needsGetter
                itemOutputs.push(@generateGetterForItem(item, enablePhp7Support))

            if item.needsSetter
                itemOutputs.push(@generateSetterForItem(item, enablePhp7Support))

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
     * @param {Object}  item
     * @param {boolean} enablePhp7Support
     *
     * @return {string}
    ###
    generateGetterForItem: (item, enablePhp7Support) ->
        returnTypeDeclaration = ''

        if enablePhp7Support and item.type != 'mixed'
            allowedTypes = item.type.split('|')

            if allowedTypes.length == 1
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
     * @param {Object}  item
     * @param {boolean} enablePhp7Support
     *
     * @return {string}
    ###
    generateSetterForItem: (item, enablePhp7Support) ->
        typePrefix = ''
        defaultValueSuffix = ''

        type = item.type
        allowedTypes = item.type.split('|')

        if allowedTypes.length > 1 and 'null' in allowedTypes
            type = (if allowedTypes[0] != 'null' then allowedTypes[0] else allowedTypes[1])

        if (enablePhp7Support or @isClassType(type)) and
            type != 'mixed' and
            (allowedTypes.length == 1 or (allowedTypes.length == 2 and 'null' in allowedTypes))
                # Make this setter's type hint nullable by specifying the default value.
                if allowedTypes.length > 1
                    defaultValueSuffix = ' = null'

                typePrefix += type + ' '

        returnTypeDeclaration = ''

        if enablePhp7Support
            returnTypeDeclaration = ': self'

        return """
            /**
             * Sets the #{item.name} to use.
             *
             * @param #{item.type} $#{item.name}
             *
             * @return $this
             */
            public function #{item.setterName}(#{typePrefix}$#{item.name}#{defaultValueSuffix})#{returnTypeDeclaration}
            {
                $this->#{item.name} = $#{item.name};
                return $this;
            }
        """
