{Point, Range} = require 'atom'

module.exports =

class ParameterParser

    parsedParameters: []

    parser: null

    constructor: (parser) ->
        @parser = parser

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

    makeUnique: (array) ->
        return array.filter (filterItem, pos, self) ->
            for i in [0 .. self.length - 1]
                return self[i].name == filterItem.name &&
                    pos == i


    buildKey: (editor, selectedBufferRange) ->
        return editor.getPath() + JSON.stringify(selectedBufferRange)

    removeCachedParameters: (editor, selectedBufferRange) ->
        key = @buildKey(editor, selectedBufferRange)
        delete @parsedParameters[key]
