{Point, Range} = require 'atom'

module.exports =

class ParameterParser

    ###*
     * Cached parameters that have already been parsed
     *
     * @type {Array}
    ###
    parsedParameters: []

    ###*
     * Parser object from the php-integrator-base service
     *
     * @type {Parser}
    ###
    parser: null

    ###*
     * Constructor
     *
     * @param {Parser} parser
    ###
    constructor: (parser) ->
        @parser = parser

    ###*
     * Takes the editor and the range and loops through finding all the
     * parameters that will be needed if this code was to be moved into
     * its own function
     *
     * @param  {TextEditor} editor
     * @param  {Range}      selectedBufferRange
     *
     * @return {Array}
    ###
    findParameters: (editor, selectedBufferRange) ->
        key = @buildKey(editor, selectedBufferRange)

        return @parsedParameters[key] if @parsedParameters[key]

        parameters = []

        editor.scanInBufferRange /\$[a-zA-Z0-9_]+/g, selectedBufferRange, (element) =>
            # Making sure we matched a variable and not a variable within a string
            descriptions = editor.scopeDescriptorForBufferPosition(element.range.start)
            indexOfDescriptor = descriptions.scopes.indexOf('variable.other.php')
            if indexOfDescriptor > -1
                parameters.push {
                    name: element.matchText,
                    range: element.range
                }

        regexFilters = [
            /as\s(\$[a-zA-Z0-9_]+)(?:\s=>\s(\$[a-zA-Z0-9_]+))?/g, # Foreach loops
            /for\s*\(\s*(\$[a-zA-Z0-9_]+)\s*=/g, # For loops
            /catch(?:.|\s)+(\$[a-zA-Z0-9_]+)/g, #Try/catch with line breaks
            /function(?:\s|.)*?((?:\$[a-zA-Z0-9_]+)).*?\)/g, # Closure/Anonymous Function
            /\s*?(\$[a-zA-Z0-9]+)\s*?=(?!>|=)/g # Variable declarations
        ]

        for filter in regexFilters
            editor.scanInBufferRange filter, selectedBufferRange, (element) =>
                variables = element.matchText.match /\$[a-zA-Z0-9]+/g
                startPoint = new Point(element.range.end.row, 0)
                scopeRange = @getRangeForCurrentScope editor, startPoint

                for variable in variables
                    parameters = parameters.filter (parameter) =>
                        if parameter.name != variable
                            return true

                        if scopeRange.containsRange(parameter.range)
                            return false

                        return true

        parameters = @makeUnique parameters

        # Removing $this from parameters as this doesn't need to be passed in
        parameters = parameters.filter (item) ->
            return item.name != '$this'

        # Grab the variable types of the parameters
        parameters = parameters.map (parameter) =>
            try
                type = @parser.getVariableType(
                    editor,
                    parameter.range.start,
                    parameter.name
                )
            catch error
                console.error 'Trying to get type of ' + parameter.name +
                    ' but the php parser threw this error: ' + error
                type = null

            if type == null
                type = "[type]"

            parameter.type = type

            return parameter


        @parsedParameters[key] = parameters

        return parameters

    ###*
     * Takes the current buffer position and returns a range of the current
     * scope that the buffer position is in.
     *
     * For example this could be the code within an if statement or closure.
     *
     * @param  {TextEditor} editor
     * @param  {Point}      bufferPosition
     *
     * @return {Range}
    ###
    getRangeForCurrentScope: (editor, bufferPosition) ->
        startScopePoint = null
        endScopePoint = null

        # First walk back until we find the start of the current scope.
        for row in [bufferPosition.row .. 0]
            line = editor.lineTextForBufferRow(row)

            continue if not line

            lastIndex = line.length - 1

            for i in [lastIndex .. 0]
                descriptions = editor.scopeDescriptorForBufferPosition(
                    [row, i]
                )
                indexOfDescriptor = descriptions.scopes.indexOf('punctuation.section.scope.begin.php')
                if indexOfDescriptor > -1
                    startScopePoint = new Point(row, 0)
                    break

            break if startScopePoint?

        # Tracks any extra scopes that might exist inside the scope we are
        # looking for.
        childScopes = 0

        # Walk forward until we find the end of the current scope
        for row in [startScopePoint.row .. editor.getLineCount()]
            line = editor.lineTextForBufferRow(row)

            continue if not line

            for i in [0 .. line.length - 1]
                descriptions = editor.scopeDescriptorForBufferPosition(
                    [row, i]
                )

                indexOfDescriptor = descriptions.scopes.indexOf('punctuation.section.scope.begin.php')
                if indexOfDescriptor > -1
                    childScopes++

                indexOfDescriptor = descriptions.scopes.indexOf('punctuation.section.scope.end.php')
                if indexOfDescriptor > -1
                    if childScopes > 0
                        childScopes--

                    if childScopes == 0
                        endScopePoint = new Point(row, i + 1)
                        break

            break if endScopePoint?

        return new Range(startScopePoint, endScopePoint)

    ###*
     * Takes an array of parameters and removes any parameters that appear more
     * that once with the same name.
     *
     * @param  {Array} array
     *
     * @return {Array}
    ###
    makeUnique: (array) ->
        return array.filter (filterItem, pos, self) ->
            for i in [0 .. self.length - 1]
                return self[i].name == filterItem.name &&
                    pos == i

    ###*
     * Generates the key used to store the parameters in the cache.
     *
     * @param  {TextEditor} editor
     * @param  {Range}      selectedBufferRange
     *
     * @return {string}
    ###
    buildKey: (editor, selectedBufferRange) ->
        return editor.getPath() + JSON.stringify(selectedBufferRange)

    ###*
     * Removes cached parameters by the editor and range given.
     *
     * @param  {TextEditor} editor
     * @param  {Range} selectedBufferRange
    ###
    removeCachedParameters: (editor, selectedBufferRange) ->
        key = @buildKey(editor, selectedBufferRange)
        delete @parsedParameters[key]
