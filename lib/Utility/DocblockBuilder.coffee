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
     *
     * @return {String}
    ###
    build: (methodName, parameters, returnVariables, tabs = false, generateDescPlaceholders = true, tabText = '') =>
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

                type = parameter.type + ' '.repeat(typePadding + 1)
                variable = parameter.name + ' '.repeat(variablePadding + 1)

                docs += @buildDocumentationLine "@param #{type} #{variable}#{descriptionPlaceholder}", tabs, tabText

        if returnVariables != null && returnVariables.length > 0
            docs += @buildLine " *", tabs, tabText

            if returnVariables.length == 1
                docs += @buildDocumentationLine "@return #{returnVariables[0].type}", tabs, tabText
            else if returnVariables.length > 1
                docs += @buildDocumentationLine "@return array", tabs, tabText

        docs += @buildLine " */", tabs, tabText

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
     *
     * @return {String}
    ###
    buildLine: (content, tabs = false, tabText = '') ->
        if tabs
            content = "#{tabText}#{content}"

        content += "\n"

        return content
