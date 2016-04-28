module.exports =
    ###*
     * List of refactoring providers.
    ###
    providers: []

    ###*
     * Activates the package.
    ###
    activate: ->

    ###*
     * Deactivates the package.
    ###
    deactivate: ->
        @deactivateProviders()

    ###*
     * Activates the providers using the specified service.
    ###
    activateProviders: (service) ->
        DocblockProvider = require './DocblockProvider'
        GetterSetterProvider = require './GetterSetterProvider'
        ExtractMethodProvider = require './ExtractMethodProvider'

        @providers = []
        @providers.push new DocblockProvider()
        @providers.push new GetterSetterProvider()
        @providers.push new ExtractMethodProvider()

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
     * Consumes the atom/snippet service
     *
     * @param {Object} snippetManager
    ###
    setSnippetManager: (snippetManager) ->
        for provider in @providers
            provider.setSnippetManager snippetManager
