{Point, Range} = require 'atom'

module.exports =

class ParameterParser

    findParameters: (editor, selectedBufferRange) ->
        parameters = []

        editor.scanInBufferRange /\$[a-zA-Z0-9_]+/g, selectedBufferRange, (element) =>
            # Making sure we matched a variable and not a variable within a string
            descriptions = editor.scopeDescriptorForBufferPosition(element.range.start)
            indexOfDescriptor = descriptions.scopes.indexOf('variable.other.php')
            if indexOfDescriptor > -1
                parameters.push element.matchText

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

                scopeText = editor.getTextInBufferRange(scopeRange)
                for variable in variables
                    variableRegex = new RegExp("\\#{variable}", "g")
                    variableOccurancesInCurrentScope = (scopeText.match(variableRegex) || []).length

                    while true
                        indexOfVariable = parameters.indexOf variable
                        parameters.splice indexOfVariable, 1

                        variableOccurancesInCurrentScope--
                        break unless variableOccurancesInCurrentScope > 0


        parameters = @makeUnique parameters

        # Removing $this from parameters as this doesn't need to be passed in
        if parameters.indexOf('$this') > -1
            indexOfThis = parameters.indexOf('$this')
            parameters.splice indexOfThis, 1

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

    makeUnique: (array) =>
        return array.filter (item, pos, self) ->
            return self.indexOf(item) == pos;
