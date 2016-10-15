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
        @providers.push new DocblockProvider()
        @providers.push new IntroducePropertyProvider()
        @providers.push new GetterSetterProvider()
        @providers.push new ExtractMethodProvider()
        @providers.push new ConstructorGenerationProvider()

        @providers.push new OverrideMethodProvider()
        @providers.push new StubAbstractMethodProvider()
        @providers.push new StubInterfaceMethodProvider()

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
