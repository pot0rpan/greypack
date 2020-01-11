// [greypack] 0.1.3
// Author: pot

printHeader = function()
	color.print(color.INFO, "<b>                    .   </b>")
	color.print(color.INFO, "<b>,-.,-.,-.. ,-.,-.,-.| , </b>")
	color.print(color.INFO, "<b>| ||  |-'| | |,-||  |<  </b>")
	color.print(color.INFO, "<b>`-|'  `-'`-|-'`-^`-'' ` </b>")
	color.print(color.INFO, "<b> ,|        |</b>   0.1.3    ")
	color.print(color.INFO, "<b> `'      `-'</b>    -pot    ")
end function

importGreypackFunc = function(funcName)
	funcStr = null
	funcs = {}
	funcs.map = "map=function(a,c)\nn=[]\ni=0\nfor el in a\nn.push(c(el,i))\ni=i+1\nend for\nreturn n\nend function"
	funcs.filter = "filter=function(a, c)\nn=[]\ni=0\nfor e in a\nif c(e,i) then n.push(e)\ni=i+1\nend for\nreturn n\nend function"
	funcs.reduce = "reduce=function(a,c,iv)\nac=null\ni=0\nif iv then\nac=iv\nelse\nac=a[0]\ni=i+1\nend if\nwhile i<a.len\nac=c(ac,a[i],i,a)\ni=i+1\nend while\nreturn ac\nend function"
	funcs.includes = "includes=function(v,a)\nfor e in a\nif e==v then return true\nend for\nreturn false\nend function"

	for func in funcs
		if funcName == func.key then
			color.print(color.INFO, "Imported <b>" + funcName + "</b> from the <u>greypack</u> lib")
			return func.value + "\n"
		end if
	end for
	
	color.print(color.ERROR, "Error: <b>" + funcName + "</b> is not a valid greypack function")
	return null
end function

exitUsage = function()
	print("<b>Usage: greypack [file.src] [options]</b>\n<b>")
	print("<b>-s, --save => Save copy of full .src file in timestamped file</b>")
	print("<b>-b, --bin => Copy built binary file to /bin</b>")
	exit("<b>-r, --run ['run args'] => Run file after building with optional arguments</b>")
end function

color = { "ERROR": "#FF44AA", "SUCCESS": "#44FF88", "INFO": "#44AAFF" }
color.print = function(hex, text)
	if not hex[0] == "#" then hex = "#" + hex
	if not hex.len == 7 then print(text)
	lines = text.split("\n")
	for line in lines
		print("<color=" + hex + ">" + line + "</color>")
	end for
end function

getParamOptions = function()
	options = { "save": false, "copyToBin": false, "run": false, "runArgs": "" }

	i = 1
	while i < params.len
		p = params[i]

		if p == "-s" or p == "--save" then options.save = true
		if p == "-b" or p == "--bin" then options.copyToBin = true
		if p == "-r" or p == "--run" then
			options.run = true
			foundEnd = false
			possibleRunArgs = params[i + 1:]

			// Populate options.runArgs if in this syntax: 'run args'
			if possibleRunArgs.len and possibleRunArgs[0][0] == "'" then
				j = 0
				runArgs = ""
				
				while j < possibleRunArgs.len and not foundEnd
					arg = possibleRunArgs[j]
					if arg[0] == "'" then arg = arg[1:] // remove leading '
					if arg[-1] == "'" then
						foundEnd = true
						arg = arg[:-1]
					end if
					runArgs = runArgs + arg + " "
					j = j + 1
				end while
				if not foundEnd then exitUsage

				options.runArgs = runArgs.trim
				i = i + j // continue loop from current spot
			end if
		end if
		i = i + 1
	end while

	return options
end function

fixRelativePath = function(relPath, absPath)
	// Set up if forward relative path ./
	if relPath[:2] == "./" then
		if not absPath[-1] == "/" then absPath = absPath + "/"
		relPath = absPath + relPath.replace("./", "")
	else if relPath[:3] == "../" then
		// Set up if backwards relative path ../
		relPathArr = relPath.split("/")
		absPathArr = absPath.split("/")[1:-1] // remove leading/trailing "" in array

		while relPathArr[0] == ".."
			relPathArr.pull // remove ".."
			absPathArr.pop // remove corresponding end of absPathArr
		end while

		relPath = "/" + (absPathArr.join("/") + "/" + relPathArr.join("/")) // construct absolute path
	end if

	return relPath
end function

parseLine = function(line, srcFileDir)
	if not srcFileDir[-1] == "/" then srcFileDir = srcFileDir + "/"

	newLine = polyfill(line)
	if not newLine then return newLine
	newLine = replaceImport(newLine, srcFileDir)

	return newLine
end function

// Replace += and -= if found
// Return null if not successful
// Return unedited line if normal line
polyfill = function(line)
	varName = ""
	operator = null
	operatorIndex = null

	if not line.indexOf("+=") == null then
		operator = "+="
		operatorIndex = line.indexOf("+=")
	else if not line.indexOf("-=") == null then
		operator = "-="
		operatorIndex = line.indexOf("-=")
	else
		return line
	end if

	i = operatorIndex - 1
	foundVarEnd = false
	while i > -1
		// Continue or exit loop if space or tab
		if code(line[i]) == 32 or code(line[i]) == 9 then
			if not foundVarEnd then
				// Keep walking back through spaces
				i = i - 1
				continue
			else
				// Found full variable name, exit loop
				break
			end if
		end if

		if not foundVarEnd then foundVarEnd = true

		varName = line[i] + varName
		i = i - 1
	end while

	if not varName.len then
		color.print(color.ERROR, "Error: Could not replace " + operator)
		return null
	end if

	// Replace
	varStartIndex = i + 1
	return line[:varStartIndex] + varName + " = " + varName + " " + operator[0] + " " + line[operatorIndex + 2:].trim
end function

// Return imported function lines if successful
// Return null if not successful
// Return unedited line if not an import statement
replaceImport = function(line, srcFileDir)
	arr = line.trim.split(" ")

	if arr.len >= 4 and arr[0].trim == "import" and arr[2].trim == "from" then
		// Get function source file content
		funcName = arr[1].trim
		funcPath = null

		// Skip searching if importing a greypack function
		if arr[3].trim[1:-1] == "greypack" then
			return importGreypackFunc(funcName)
		else
			funcPath = fixRelativePath(arr[3].trim[1:-1], srcFileDir) // [1:-1] removes "" around path
		end if

		funcFile = get_shell.host_computer.File(funcPath)
		if not funcFile then
			color.print(color.ERROR, "Error: Could not find file <u>" + funcPath + "</u>")
			return null
		end if
		funcFileContent = funcFile.content.split("\n")
		
		// Add function text to foundFunc
		foundFunc = ""
		foundStart = false
		foundEnd = false
		_lineNum = 1
		for _line in funcFileContent
			// indexOf returns null if not found
			if (_line.indexOf(funcName + " ") == 0 or _line.indexOf(funcName + "=") == 0) and not _line.indexOf("=") == null and not _line.indexOf("function") == null then
				foundStart = true
			end if

			if foundStart and not foundEnd then
				// Recursively parse lines
				recursive_line = replaceImport(_line, funcFile.path.split("/")[:-1].join("/"))
				if not recursive_line then
					color.print(color.ERROR, "Error: Could not resolve function <b>" + funcName + "</b> in <u>" + funcPath + "</u>")
					color.print(color.ERROR, "[Line " + _lineNum + ": " + funcPath.split("/")[-1] + "]")
					return null
				end if

				if recursive_line == _line then
					// Just add current line of function
					foundFunc = foundFunc + _line + "\n\n"
				else
					// Add recursively found function before current function
					foundFunc = recursive_line + "\n\n" + foundFunc + "\n\n"
				end if
			end if
			if not _line.indexOf("end function") == null then
				foundEnd = true
			end if
			_lineNum = _lineNum + 1
		end for
		
		// If the function was found, replace line with function content
		// Otherwise error out, since file wont build anyways
		if foundStart and foundEnd then
			line = foundFunc[:-2] // remove trailing \n
			color.print(color.INFO, "Imported <b>" + funcName + "</b> from <u>" + funcPath + "</u>")
		else
			color.print(color.ERROR, "Error: Could not resolve function <b>" + funcName + "</b> in <u>" + funcPath + "</u>")
			return null
		end if
	end if
	
	return line // return successful imported function(s), or the unedited line
end function

assembleFile = function(srcFileLinesArr, srcFileDir, srcFileName)
	assembledFileContent = []
	lineNum = 1

	for line in srcFileLinesArr
		line = parseLine(line, srcFileDir)
		if not line then
			color.print(color.ERROR, "[Line " + lineNum + ": " + srcFileName + "]")
			return null
		end if
		assembledFileContent.push(line)
		lineNum = lineNum + 1
	end for

	return assembledFileContent.join("\n")
end function

touchFolder = function(relativePath, folderName)
	color.print(color.INFO, "Creating <b>/" + folderName + "</b> folder in .src file directory...")
	get_shell.host_computer.create_folder(relativePath, folderName)
	return comp.File(relativePath + folderName)
end function

touchFile = function(fileName, buildPath, content)
	color.print(color.INFO, "Saving <b>" + fileName + "</b> file...")
	get_shell.host_computer.touch(buildPath, fileName)
	file = get_shell.host_computer.File(buildPath + "/" + fileName)
	if content then file.set_content(content)
	return file
end function

run = function(path, args)
	fileName = path.split("/")[-1]
	color.print(color.INFO, " \nRunning >> <b>" + fileName + " " + args + "</b>")
	get_shell.launch(path, args)
end function


if params.len < 1 or params[0] == "-h" or params[0] == "--help" or params[0] == "help" then exitUsage
printHeader

CHAR_LIMIT = 80000
comp = get_shell.host_computer
srcPath = params[0]
srcFile = comp.File(srcPath)
relativePath = srcFile.path.split("/")[:-1].join("/") + "/"
buildFolderName = "build"
buildFolder = comp.File(relativePath + buildFolderName)
options = getParamOptions

while true // Rebuild on Enter
	color.print(color.INFO, "Parsing " + srcFile.name + "...")
	color.print(color.INFO, "Resolving imports...")
	srcFileLinesArr = srcFile.content.split("\n")

	// Replace imports with their actual functions
	color.print(color.INFO, "Assembling full <b>" + srcFile.name + "</b> file...")
	assembledFileContent = assembleFile(srcFileLinesArr, relativePath[:-1], srcFile.name)

	// Make sure assembled file is under 80,000 character limit
	if assembledFileContent and assembledFileContent.len > CHAR_LIMIT then
		color.print(color.ERROR, "Error: Assembled file is " + (assembledFileContent.len - CHAR_LIMIT) + " characters over max file size limit")
		assembledFileContent = null
	end if

	if assembledFileContent then
		// Create build folder to put full source and binary in
		if not buildFolder then buildFolder = touchFolder(relativePath, buildFolderName)

		// Create file containing full source with imported functions
		assembledFile = touchFile(srcFile.name, buildFolder.path, assembledFileContent)

		// Create timestamped file if --save option
		if options.save then
			time = current_date.split(" ")[-1].replace(":", "")
			timeFileName = srcFile.name.split(".").join(time + ".")
			
			// Touch is faster than copying
			touchFile(timeFileName, buildFolder.path, assembledFileContent)
		end if

		// Build completed file
		color.print(color.INFO, "Building <b>" + srcFile.name[:-4] + "</b>...")
		get_shell.build(assembledFile.path, buildFolder.path)

		// Copy built file to bin if --bin option
		if options.copyToBin then
			color.print(color.INFO, "Copying binary to <b>/bin</b>...")
			get_shell.build(assembledFile.path, "/bin")
		end if

		color.print(color.SUCCESS, "Done. Built files can be viewed in the /build folder of the source directory")

		// Run built file if --run option
		if options.run then run(buildFolder.path + "/" + srcFile.name[:-4], options.runArgs)
	end if // not buildError

	andRun = ""
	if options.run then andRun = " and run"
	user_input("\n<color=" + color.INFO + "><b>Press Enter to rebuild" + andRun + ", or Ctrl+C to exit</b></color>")
end while
