## 0.5.0 (base 0.9.0)
* Tweaked some defaults.
* Add basic support for generating docblocks (by typing `/**` and pressing `alt-enter`).
* *Important*: The [intentions](https://github.com/steelbrain/intentions) package is now required.
  * You can now use intentions (bound to alt-enter by default) to perform various refactoring actions in certain contexts, for example:
    * Press alt-enter when code is selected to extract a method.
    * Press alt-enter inside a classlike to generate getters and setters.
    * Press alt-enter with the cursor on a method name to generate its docblock.

## 0.4.2 (base 0.8.0)
* Update to use the most recent version of the base service.

## 0.4.1
* Don't throw an error when no current class name is found.
* Perform more operations asynchronously whilst fetching properties for generating getters and setters, improving responsiveness.

## 0.4.0 (base 0.7.0)
* Fixed promise rejections not being handled.
* Added support for extracting methods based on CWDN's original [php-extract-method](https://github.com/CWDN/php-extract-method) package (thanks to @CWDN).
* When generating setters, type hints will no longer be generated if multiple types are possible (with the exception of a type-hintable type and `null`, see also below).
* When generating setters for type-hintable types that are also nullable, such as `Foo|null` or even `string|null` in PHP 7, an `= null` will now be added to the setter's parameter.

## 0.3.0 (base 0.6.0)
* Added support for generating PHP 7 getters and setters.
* Added the keyboard shortcut `shift + return` for confirming dialogs (cfr. git-plus).

## 0.2.0 (base 0.5.0)
* Initial release.
