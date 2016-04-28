module.exports =

class DocblockBuilder
    ###*
     * Builds the docblock for the given method and parameters.
     *
     * @param  {String}     methodName
     * @param  {Array}      parameters
     * @param  {Array|null} returnVariables
     * @param  {Boolean}    tabs                     = false
     * @param  {Boolean}    generateDescPlaceholders = true
     * @param  {String}     tabText
     * @param  {Boolean}    doFinalNewline
     *
     * @return {String}
    ###
    build: (methodName, parameters, returnVariables, tabs = false, generateDescPlaceholders = true, tabText = '', doFinalNewline = true) =>
        docs = @buildLine "/**", tabs, tabText

        if generateDescPlaceholders
            docs += @buildDocumentationLine "[#{methodName} description]", tabs, tabText

        if parameters.length > 0
            descriptionPlaceholder = ""
            if generateDescPlaceholders
                docs += @buildLine " *", tabs, tabText
                descriptionPlaceholder = " [description]"
            longestType = 0
            longestVariable = 0

            for parameter in parameters
                if parameter.type.length > longestType
                    longestType = parameter.type.length
                if parameter.name.length > longestVariable
                    longestVariable = parameter.name.length

            for parameter in parameters
                typePadding = longestType - parameter.type.length
                variablePadding = longestVariable - parameter.name.length

                type = parameter.type + new Array(typePadding + 1).join(' ')
                variable = parameter.name + new Array(variablePadding + 1).join(' ')

                docs += @buildDocumentationLine "@param #{type} #{variable}#{descriptionPlaceholder}", tabs, tabText

        if returnVariables != null && returnVariables.length > 0
            docs += @buildLine " *", tabs, tabText

            if returnVariables.length == 1
                docs += @buildDocumentationLine "@return #{returnVariables[0].type}", tabs, tabText
            else if returnVariables.length > 1
                docs += @buildDocumentationLine "@return array", tabs, tabText

        docs += @buildLine " */", tabs, tabText, doFinalNewline

        return docs

    ###*
     * Builds a documentation line. This uses buildLine function just with
     * " * " prefixed to the content.
     *
     * @param  {String}  content
     * @param  {Boolean} tabs    = false
     * @param  {String}  tabText
     *
     * @return {String}
    ###
    buildDocumentationLine: (content, tabs = false, tabText = '') ->
        content = " * #{content}"
        return @buildLine(content, tabs, tabText)


    ###*
     * Builds a single line of the new method. This will add a new line to the
     * end and add any tabs that are needed (if requested).
     *
     * @param  {String}  content
     * @param  {Boolean} tabs    = false
     * @param  {String}  tabText
     * @param  {Boolean} doNewline
     *
     * @return {String}
    ###
    buildLine: (content, tabs = false, tabText = '', doNewLine = true) ->
        if tabs
            content = "#{tabText}#{content}"

        if doNewLine
            content += "\n"

        return content
