// [greypack] 0.1.1
// Author: pot

if params.len < 1 or params[0] == "-h" or params[0] == "--help" or params[0] == "help" then
	print("<b>Usage: greypack [file.src] [options]</b>\n<b>")
	print("<b>-s, --save => Save copy of full .src file in timestamped file</b>")
	print("<b>-b, --bin => Copy built file to /bin</b>")
	exit("<b>-r, --run [run args] => Run file after building</b>")
end if


color = { "ERROR": "#FF44AA", "SUCCESS": "#44FF88", "INFO": "#44AAFF" }
color.print = function(hex, text)
	if not hex[0] == "#" then hex = "#" + hex
	if not hex.len == 7 then print(text)
	lines = text.split("\n")
	for line in lines
		print("<color=" + hex + ">" + line + "</color>")
	end for
end function

getOptions = function()
	options = { "save": false, "copyToBin": false, "run": false, "runArgs": "" }

	i = 1
	while i < params.len
		p = params[i]
		if p == "-s" or p == "--save" then options.save = true
		if p == "-b" or p == "--bin" then options.copyToBin = true
		if p == "-r" or p == "--run" then
			options.run = true
			for arg in params[i + 1:]
				options.runArgs = options.runArgs + " " + arg
			end for
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

// Return imported function lines if successful
// Return null if not successful
// Return unedited line if not an import statement
replaceImport = function(line, srcFileDir)
	if not srcFileDir[-1] == "/" then srcFileDir = srcFileDir + "/"
	arr = line.trim.split(" ")

	if arr.len >= 4 and arr[0].trim == "import" and arr[2].trim == "from" then
		// Get function source file content
		funcName = arr[1].trim
		funcPath = fixRelativePath(arr[3].trim[1:-1], srcFileDir) // [1:-1] removes "" around path

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
				// Recursively search for more imports
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
	assembledFileContent = ""
	lineNum = 1

	for line in srcFileLinesArr
		line = replaceImport(line, srcFileDir)
		if not line then
			color.print(color.ERROR, "[Line " + lineNum + ": " + srcFileName + "]")
			return null
		end if
		assembledFileContent = assembledFileContent + line + "\n"
		lineNum = lineNum + 1
	end for

	return assembledFileContent
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


color.print(color.INFO, "<b>                    .   </b>")
color.print(color.INFO, "<b>,-.,-.,-.. ,-.,-.,-.| , </b>")
color.print(color.INFO, "<b>| ||  |-'| | |,-||  |<  </b>")
color.print(color.INFO, "<b>`-|'  `-'`-|-'`-^`-'' ` </b>")
color.print(color.INFO, "<b> ,|        |</b>   0.1.1    ")
color.print(color.INFO, "<b> `'      `-'</b>    -pot    ")


CHAR_LIMIT = 80000
comp = get_shell.host_computer
srcPath = params[0]
srcFile = comp.File(srcPath)
relativePath = srcFile.path.split("/")[:-1].join("/") + "/"
buildFolderName = "build"
buildFolder = comp.File(relativePath + buildFolderName)
options = getOptions

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
