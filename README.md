# **greypack v0.1.2**

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

```
import test from "./functionsFile.src"

print(test)
```

This main source file should have all `import` statements at the top of the file. During the assembling process, all imported function definitions will replace those `import` statements.

Path can be absolute or relative. If relative, start with `./` to access the file's current directory, or use `../` to move up a directory.

#### Imported function

_functionsFile.src_

```
test = function()
    return "It works!"
end function
```

Currently, all imported functions must be self contained with no side-effects or reaching outside of their function body. Any external objects needed, like files, shells, or other functions should be passed into the function as arguments.

Greypack does not yet parse included functions for anything other than `import` statements, so while the following code block may not throw any errors during the assembling process, it will NOT work.

_**THIS WILL NOT WORK:**_

```
str = "A string that will NOT be included, breaking the function"

test = function()
    return str
end function
```

Currently only function imports are supported. If you need to access other functions in the same file as an imported function, make sure you include them too.

**This will work**:

_mainFile.src_

```
import testA from "./functionsFile.src"
import testB from "./functionsFile.src"

print(testA)
```

_functionsFile.src_

```
testA = function()
  return testB
end function

testB = function()
  return "This works since all needed functions are imported"
end function
```

\*If you want to import a variable for usage, you can wrap it in a function, like in the example above where `testB` returns a string. It's an ugly and annoying workaround, but it works.

_variables.src_

```
colors = function()
  return { "red": "#FF0000", "green": "#00FF00", "blue": "#0000FF" }
end function
```

```
import colors from "./colors.src"

print("<color=" + colors.green + ">This is how to access a variable</color>")
```

#### Nested imported function

Included functions can also include their own external functions. Any other imports they rely on must be inside their function body, or at the top of the main source file like the example above.

```
test = function(message)
    import otherFunction from "./otherFunctions.src"

    return "Nested imports work too, " + otherFunction(message)
end function
```

## Output

Here is what greypack does when assembling the final file:

_providedFile.src_

```
import test from "../example/functionsFile.src"

print(test)
```

Final assembled version of _providedFile.src_

```
test = function()
    return "It works!"
end function

print(test)
```

## Screenshots

**Successful Build**

![Screenshot of a successful build](https://github.com/pot-gh/greypack/blob/master/screenshots/gpsuccess.png)

**Errors**

If an error occurs during the assembling process, a trace of where the error occurred is printed to help with debugging.

![Screenshot of a build error](https://github.com/pot-gh/greypack/blob/master/screenshots/gperror.png)
