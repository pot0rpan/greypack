\*\* New in v0.2.0: Added support for `+=` and `-=` [operators ↓](#operators)

\*\* New in v0.1.3: Import utility functions built into the new [greypack lib ↓](#greypack-lib)

# **greypack v0.2.0**

Greypack is a code bundling tool based off of the JavaScript bundling tool Webpack, and was also insipred by @cptnwinky's similar project [Gscript.Compiler](https://ghcommunity.cc/t/gscript-compiler/64).

## Usage

**Standard Usage**

`greypack path/to/file.src`

The fully assembled source file and the built binary file are both saved in a **/build** folder of the provided source file's directory by default. The following options allow more functionality:

**Save copy of assembled .src file with timestamp**

`greypack path/to/file.src -s`

**Copy built file to /bin**

`greypack path/to/file.src -b`

**Run binary after building**

`greypack path/to/file.src -r ['run args']`

## Import Syntax

#### Main source file

```lua
import test from "./functionsFile.src"

print(test)
```

This main source file should have all `import` statements at the top of the file. During the assembling process, all imported function definitions will replace those `import` statements.

Path can be absolute or relative. If relative, start with `./` to access the file's current directory, or use `../` to move up a directory.

#### Imported function

_functionsFile.src_

```lua
test = function()
		return "It works!"
end function
```

Currently, all imported functions must be self contained with no side-effects or reaching outside of their function body. Any external objects needed, like files, shells, or other functions should be passed into the function as arguments.

Greypack does not yet parse included functions for anything other than `import` statements, so while the following code block may not throw any errors during the assembling process, it will NOT work.

_**THIS WILL NOT WORK:**_

```lua
str = "A string that will NOT be included, breaking the function"

test = function()
		return str
end function
```

Currently only function imports are supported. If you need to access other functions in the same file as an imported function, make sure you include them too.

**This will work**:

_mainFile.src_

```lua
import testA from "./functionsFile.src"
import testB from "./functionsFile.src"

print(testA)
```

_functionsFile.src_

```lua
testA = function()
	return testB
end function

testB = function()
	return "This works since all needed functions are imported"
end function
```

\*If you want to import a variable for usage, you can wrap it in a function, like in the example above where `testB` returns a string. It's an ugly and annoying workaround, but it works.

_variables.src_

```lua
colors = function()
	return { "red": "#FF0000", "green": "#00FF00", "blue": "#0000FF" }
end function
```

```lua
import colors from "./colors.src"

print("<color=" + colors.green + ">This is how to access a variable</color>")
```

#### Nested imported function

Included functions can also include their own external functions. Any other imports they rely on must be inside their function body, or at the top of the main source file like the example above.

```lua
test = function(message)
		import otherFunction from "./otherFunctions.src"

		return "Nested imports work too, " + otherFunction(message)
end function
```

## Output

Here is what greypack does when assembling the final file:

_providedFile.src_

```lua
import test from "../example/functionsFile.src"

print(test)
```

Final assembled version of _providedFile.src_

```lua
test = function()
		return "It works!"
end function

print(test)
```

## Greypack Lib

Starting with v0.1.3, greypack comes with some built-in utility functions, and will be adding more as new needs arise. Simply use the following syntax to include them in your project:

`import functionName from "greypack"`

Then to pass a function as an argument _without_ running it, add `@` to the beginning like:

`@functionName`

Listed below are the currently available functions and how to use them.

**map(array, callback)**

_"creates a new array with the results of calling a provided function on every element in the calling array" - [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map)_

```lua
import map from "greypack"

array = [1, 2, 3]
callback = function(element, index)
	return element * index
end function

print(array) // [1, 2, 3]
print(map(arr, @callback)) // [0, 2, 6]
```

**filter(array, callback)**

_"creates a new array with all elements that pass the test implemented by the provided function" - [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/filter)_

```lua
import filter from "greypack"

array = [1, 2, 3]
callback = function(element, index)
	return element > 1
end function

print(array) // [1, 2, 3]
print(filter(array, @callback)) // [2, 3]
```

**reduce(array, callback)**

_"executes a reducer function (that you provide) on each element of the array, resulting in a single output value" - [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/Reduce)_

```lua
import reduce from "greypack"

arr = [1, 2, 3]
callback = function(accumulator, currentValue, currentIndex, array)
	return accumulator + currentValue
end function

print(arr) // [1, 2, 3]
print(reduce(arr, @callback)) // 6
```

**includes(value, array)**

_"determines whether an array includes a certain value among its entries, returning 1 or 0 as appropriate" - [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/includes)_

```lua
array = [1, 2, 3]

print(array) // [1, 2, 3]
print(includes(2, array)) // 1
print(includes(4, array)) // 0
```

## Operators

Greypack adds support for operators available in other languages that aren't implemented in Grey Script. The following are currently supported:

- `+=`
- `-=`

Example:

```lua
i = 0
while i < 10
	if i % 2 == 0 then i -= 1
	i += 2
end while
```

becomes:

```lua
i = 0
while i < 10
	if i % 2 == 0 then i = i - 1
	i = i + 2
end while
```

## Screenshots

**Successful Build**

![Screenshot of a successful build](https://github.com/pot-gh/greypack/blob/master/screenshots/gpsuccess.png)

**Errors**

If an error occurs during the assembling process, a trace of where the error occurred is printed to help with debugging.

![Screenshot of a build error](https://github.com/pot-gh/greypack/blob/master/screenshots/gperror.png)
