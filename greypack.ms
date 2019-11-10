// [greypack] 0.1.0
// Author: pot

if params.len < 1 or params[0] == "-h" or params[0] == "--help" or params[0] == "help" then
	print("<b>Usage: greypack [file.src] [options]</b>\n<b>")
	print("<b>-s, --save => Save full .src file in timestamped file</b>")
	print("<b>-b, --bin => Copy built file to /bin</b>")
	exit("<b>-r, --run [run args] => Run file after building</b>")
end if

getOptions = function()
	options = {}
	options.save = false
	options.copyToBin = false
	options.run = false
	options.runArgs = ""

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

// Return imported function lines if successful
// Return null if not successful
// Return unedited line if not an import statement
replaceImport = function(line, srcFileDir)
	if not srcFileDir[-1] == "/" then srcFileDir = srcFileDir + "/"
	arr = line.trim.split(" ")

	if arr.len >= 4 and arr[0].trim == "import" and arr[2].trim == "from" then
		// Get function source file content
		funcName = arr[1].trim
		funcPath = arr[3].trim[1:-1] // remove ""

		// Set up if forward relative path ./
		if funcPath[:2] == "./" then
			if not srcFileDir[-1] == "/" then srcFileDir = srcFileDir + "/"
			funcPath = srcFileDir + funcPath.replace("./", "")
		end if

		// Set up if backwards relative path ../
		if funcPath[:3] == "../" then
			funcPathArr = funcPath.split("/")
			srcPathArr = srcFileDir.split("/")[1:-1] // remove leading/trailing "" in array

			while funcPathArr[0] == ".."
				funcPathArr = funcPathArr[1:] // remove ".."
				srcPathArr.pop // remove end of srcPathArr
			end while

			funcPath = "/" + (srcPathArr.join("/") + "/" + funcPathArr.join("/")) // construct absolute path
		end if

		funcFile = get_shell.host_computer.File(funcPath)
		if not funcFile then
			print("<color=#ff44aa>Error: Could not find file <u>" + funcPath + "</u></color>")
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
			if (not _line.indexOf(funcName + " ") == null or not _line.indexOf(funcName + "=") == null) and not _line.indexOf("=") == null and not _line.indexOf("function") == null then
				foundStart = true
			end if

			if foundStart and not foundEnd then
				// Recursively search for more imports
				recursive_line = replaceImport(_line, funcFile.path.split("/")[:-1].join("/"))
				if not recursive_line then
					print("<color=#ff44aa>Error: Could not resolve function <b>" + funcName + "</b> in <u>" + funcPath + "</u></color>")
					print("<color=#ff44aa>[Line " + _lineNum + ": " + funcPath.split("/")[-1] + "]</color>")
					return null
				end if

				if not recursive_line == _line then
					// Add recursively found function before current function
					foundFunc = recursive_line + "\n\n" + foundFunc + "\n"
				else
					// Just add current line of function
					foundFunc = foundFunc + _line + "\n"
				end if
			end if
			if not _line .indexOf("end function") == null then
				foundEnd = true
			end if
			_lineNum = _lineNum + 1
		end for
		
		// If the function was found, replace line with function content
		// Otherwise error out, since file wont build anyways
		if foundStart and foundEnd then
			line = foundFunc[:-2] // remove trailing \n
			print("<color=#44aaff>Imported <b>" + funcName + "</b> from <u>" + funcPath + "</u></color>")
		else
			print("<color=#ff44aa>Error: Could not resolve function <b>" + funcName + "</b> in <u>" + funcPath + "</u></color>")
			return null
		end if
	end if
	
	return line // return successful imported function(s), or the unedited line
end function


print("<color=#44aaff><b>                    .   </b></color>")
print("<color=#44aaff><b>,-.,-.,-.. ,-.,-.,-.| , </b></color>")
print("<color=#44aaff><b>| ||  |-'| | |,-||  |<  </b></color>")
print("<color=#44aaff><b>`-|'  `-'`-|-'`-^`-'' ` </b></color>")
print("<color=#44aaff><b> ,|        |</b>   0.0.1    </color>")
print("<color=#44aaff><b> `'      `-'            </b></color>")


comp = get_shell.host_computer
srcPath = params[0]
srcFile = comp.File(srcPath)
relativePath = srcFile.path.split("/")[:-1].join("/") + "/"
buildFolderName = "build"
buildFolder = comp.File(relativePath + buildFolderName)
options = getOptions

while true // Rebuild on Enter
	print("<color=#44aaff>Parsing " + srcFile.name + "...</color>")
	print("<color=#44aaff>Resolving imports...</color>")
	srcFileContent = srcFile.content.split("\n")
	buildError = false

	// Replace imports with their actual functions
	builtFileContent = ""
	lineNum = 1
	for line in srcFileContent
		line = replaceImport(line, srcFile.path.split("/")[:-1].join("/"))
		if not line then
			print("<color=#ff44aa>[Line " + lineNum + ": " + srcFile.name + "]</color>")
			buildError = true
			break
		end if
		builtFileContent = builtFileContent + line + "\n"
		lineNum = lineNum + 1
	end for

	if not buildError then
		// Create build folder to put full source in
		if not buildFolder then
			print("<color=#44aaff>Creating <b>/build</b> folder in .src file directory...</color>")
			comp.create_folder(relativePath, buildFolderName)
			buildFolder = comp.File(relativePath + buildFolderName)
		end if

		// Create file containing full source with imported functions
		print("<color=#44aaff>Assembling full <b>" + srcFile.name + "</b> file...</color>")
		comp.touch(buildFolder.path, srcFile.name)
		buildFile = comp.File(buildFolder.path + "/" + srcFile.name)
		buildFile.set_content(builtFileContent)

		// Create timestamped file if --save option
		if options.save then
			time = current_date.split(" ")[-1].replace(":", "")
			timeFileName = srcFile.name.split(".").join(time + ".")
			print("<color=#44aaff>Saving timestamped <b>" + timeFileName + "</b> file...</color>")
			
			// Touch is faster than copying
			comp.touch(buildFolder.path, timeFileName)
			timestampedFile = comp.File(buildFolder.path + "/" + timeFileName)
			timestampedFile.set_content(builtFileContent)
		end if

		// Build completed file
		print("<color=#44aaff>Building <b>" + srcFile.name[:-4] + "</b>...</color>")
		get_shell.build(buildFile.path, buildFolder.path)

		// Copy built file to bin if --bin option
		if options.copyToBin then
			get_shell.build(buildFile.path, "/bin")
			print("<color=#44aaff>Copying binary to <b>/bin</b>...</color>")
		end if

		print("<color=#44ff88>Done. Built files can be viewed in the /build folder of the source directory</color>")

		// Run built file if --run option
		if options.run then
			print("\n<color=#44aaff>Running >> <b>" + srcFile.name[:-4] + " " + options.runArgs + "</b></color>")
			get_shell.launch(buildFolder.path + "/" + srcFile.name[:-4], options.runArgs)
		end if
	end if // not buildError

	andRun = ""
	if options.run then andRun = " and run"
	user_input("\n<color=#44aaff><b>Press Enter to rebuild" + andRun + ", or Ctrl+C to exit</b></color>")
end while
