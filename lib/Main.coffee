module.exports =
    ###*
     * List of refactoring providers.
    ###
    providers: []

    ###*
     * Activates the package.
    ###
    activate: ->
        DocblockProvider = require './DocblockProvider'
        GetterSetterProvider = require './GetterSetterProvider'
        ExtractMethodProvider = require './ExtractMethodProvider'
        StubAbstractMethodProvider = require './StubAbstractMethodProvider'
        StubInterfaceMethodProvider = require './StubInterfaceMethodProvider'
        ConstructorGenerationProvider = require './ConstructorGenerationProvider'

        @providers = []
        @providers.push new DocblockProvider()
        @providers.push new GetterSetterProvider()
        @providers.push new ExtractMethodProvider()
        @providers.push new ConstructorGenerationProvider()
        
        @providers.push new StubAbstractMethodProvider()
        @providers.push new StubInterfaceMethodProvider()

    ###*
     * Deactivates the package.
    ###
    deactivate: ->
        @deactivateProviders()

    ###*
     * Activates the providers using the specified service.
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
     * @param {mixed} service
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
     * @return {array}
    ###
    provideIntentions: () ->
        intentionProviders = []

        for provider in @providers
            intentionProviders = intentionProviders.concat(provider.getIntentionProviders())

        return intentionProviders
