## 1.3.1
* Fix deprecations.

## 1.3.0 (base 2.0.0)
* The extract method preview panel is now syntax highlighted.
* Fix docblocks for constructors sometimes getting a `@return self`.
* Fix the button bar in dialogs falling outside the bottom of the dialog.
* The intentions package will now be installed automatically, if necessary.
* Fix not being able to generate a constructor in classes that have no properties.
* The default access modifier when extracting methods is now `protected` since you seldom want to expose new methods in a class' API whilst extracting methods.
* When generating method bodies, your preferred line length will now be taken into account. This means that parameter lists will be automatically wrapped over multiple lines if they are too long.
* The `Enable PHP 7 Support` checkboxes have been removed. Whether or not PHP 7 is to be used is now determined automatically from your project's PHP version. No more having to manually click the checkbox every time.
* Generated setters will no longer return `self` in PHP 7. The docblock type will still indicate `static`, but making the return type hint `self` will prevent them from being overridden to return a child class instance.
* When overriding methods that have a return value, code will now be generated that catches and returns the return value from the automatically generated `parent::` call.
  * This is useful as usually one adds additional logic but still returns or further manipulates the parent value.

## 1.1.1
* Rename the package and repository.

## 1.1.0
* Added the ability to introduce new class properties.
* Updated atom-space-pen-views to 2.2.0. This causes modal dialogs not to disappear when Atom is unfocused.

## 1.0.0 (base 1.0.0)
* Rewrote the code to support multiple types.
* Added the ability to generate constructors.
* Added the ability to override existing methods.
* Added the ability to generate unimplemented abstract methods.
* Added the ability to generate unimplemented interface methods.
* The getter and setter generator will now maintain the indentation level of the cursor.
* Fixed parameters types and the return type not always being localized when extracting a method.
* Fixed the extract method preview wrapping code to the next line instead of providing a horizontal scrollbar.
* Lists are no longer alphabetically sorted. The ordering they are returned in is now maintained, which feels more fluent as it is the same order the items are defined in.

* The docblock generator learned how to properly generate docblocks for variadic parameters:

```php
// -- Before
/**
 * @param Foo $foo
 */
protected function (Foo ...$foo) {}

// -- After
/**
 * @param Foo[] ...$foo
 */
protected function (Foo ...$foo) {}
```

## 0.5.0 (base 0.9.0)
* Tweaked some defaults.
* Add basic support for generating docblocks.
* Setters will now generate a docblock with `@return static` instead of `@return $this`. The latter is not mentioned by the draft PSR-5 anymore.
* The extract method command will now suggest class names relative to the use statements when type hinting (rather than always suggest an FQCN).
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
