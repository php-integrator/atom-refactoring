module.exports =
    ###*
     * The name of the package.
     *
     * @var {String}
    ###
    packageName: 'php-integrator-refactoring'

    ###*
     * List of refactoring providers.
     *
     * @var {Array}
    ###
    providers: []

    ###*
     * @var {Object|null}
    ###
    typeHelper: null

    ###*
     * @var {Object|null}
    ###
    docblockBuilder: null

    ###*
     * @var {Object|null}
    ###
    functionBuilder: null

    ###*
     * @var {Object|null}
    ###
    parameterParser: null

    ###*
     * @var {Object|null}
    ###
    builder: null

    ###*
     * Activates the package.
    ###
    activate: ->
        DocblockProvider = require './DocblockProvider'
        GetterSetterProvider = require './GetterSetterProvider'
        ExtractMethodProvider = require './ExtractMethodProvider'
        OverrideMethodProvider = require './OverrideMethodProvider'
        IntroducePropertyProvider = require './IntroducePropertyProvider'
        StubAbstractMethodProvider = require './StubAbstractMethodProvider'
        StubInterfaceMethodProvider = require './StubInterfaceMethodProvider'
        ConstructorGenerationProvider = require './ConstructorGenerationProvider'

        @providers = []
        @providers.push new DocblockProvider(@getTypeHelper(), @getDocblockBuilder())
        @providers.push new IntroducePropertyProvider(@getDocblockBuilder())
        @providers.push new GetterSetterProvider(@getTypeHelper(), @getFunctionBuilder(), @getDocblockBuilder())
        @providers.push new ExtractMethodProvider(@getBuilder())
        @providers.push new ConstructorGenerationProvider(@getTypeHelper(), @getFunctionBuilder(), @getDocblockBuilder())

        @providers.push new OverrideMethodProvider(@getDocblockBuilder(), @getFunctionBuilder())
        @providers.push new StubAbstractMethodProvider(@getDocblockBuilder(), @getFunctionBuilder())
        @providers.push new StubInterfaceMethodProvider(@getDocblockBuilder(), @getFunctionBuilder())

        require('atom-package-deps').install(@packageName)

    ###*
     * Deactivates the package.
    ###
    deactivate: ->
        @deactivateProviders()

    ###*
     * Activates the providers using the specified service.
     *
     * @param {Object} service
    ###
    activateProviders: (service) ->
        for provider in @providers
            provider.activate(service)

    ###*
     * Deactivates any active providers.
    ###
    deactivateProviders: () ->
        for provider in @providers
            provider.deactivate()

        @providers = []

    ###*
     * Sets the php-integrator service.
     *
     * @param {Object} service
     *
     * @return {Disposable}
    ###
    setService: (service) ->
        @activateProviders(service)
        @getBuilder().setService(service)
        @getTypeHelper().setService(service)

        {Disposable} = require 'atom'

        return new Disposable => @deactivateProviders()

    ###*
     * Consumes the atom/snippet service.
     *
     * @param {Object} snippetManager
    ###
    setSnippetManager: (snippetManager) ->
        for provider in @providers
            provider.setSnippetManager snippetManager

    ###*
     * Returns a list of intention providers.
     *
     * @return {Array}
    ###
    provideIntentions: () ->
        intentionProviders = []

        for provider in @providers
            intentionProviders = intentionProviders.concat(provider.getIntentionProviders())

        return intentionProviders

    ###*
     * @return {TypeHelper}
    ###
    getTypeHelper: () ->
        if not @typeHelper?
            TypeHelper = require './Utility/TypeHelper'

            @typeHelper = new TypeHelper()

        return @typeHelper

    ###*
     * @return {DocblockBuilder}
    ###
    getDocblockBuilder: () ->
        if not @docblockBuilder?
            DocblockBuilder = require './Utility/DocblockBuilder'

            @docblockBuilder = new DocblockBuilder()

        return @docblockBuilder

    ###*
     * @return {FunctionBuilder}
    ###
    getFunctionBuilder: () ->
        if not @functionBuilder?
            FunctionBuilder = require './Utility/FunctionBuilder'

            @functionBuilder = new FunctionBuilder()

        return @functionBuilder

    ###*
     * @return {ParameterParser}
    ###
    getParameterParser: () ->
        if not @parameterParser?
            ParameterParser = require './ExtractMethodProvider/ParameterParser'

            @parameterParser = new ParameterParser(@getTypeHelper())

        return @parameterParser

    ###*
     * @return {Builder}
    ###
    getBuilder: () ->
        if not @builder?
            Builder = require './ExtractMethodProvider/Builder'

            @builder = new Builder(
                @getParameterParser(),
                @getDocblockBuilder(),
                @getFunctionBuilder(),
                @getTypeHelper()
            )

        return @builder
