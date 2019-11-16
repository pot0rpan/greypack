test = function(desc, func, argsArr, expected)
	n = argsArr.len
	result = null

	// Temporary? Not sure how else to do this, need spread operator
	if n == 0 then result = func
	if n == 1 then result = func(argsArr[0])
	if n == 2 then result = func(argsArr[0], argsArr[1])
	if n == 3 then result = func(argsArr[0], argsArr[1], argsArr[2])
	if n == 4 then result = func(argsArr[0], argsArr[1], argsArr[2], argsArr[3])
	if n == 5 then result = func(argsArr[0], argsArr[1], argsArr[2], argsArr[3], argsArr[4])
	if n == 6 then result = func(argsArr[0], argsArr[1], argsArr[2], argsArr[3], argsArr[4], argsArr[5])
	if n == 7 then result = func(argsArr[0], argsArr[1], argsArr[2], argsArr[3], argsArr[4], argsArr[5], argsArr[6])
	if n == 8 then result = func(argsArr[0], argsArr[1], argsArr[2], argsArr[3], argsArr[4], argsArr[5], argsArr[6], argsArr[7])
	if n == 9 then result = func(argsArr[0], argsArr[1], argsArr[2], argsArr[3], argsArr[4], argsArr[5], argsArr[6], argsArr[7], argsArr[8])
	if n == 10 then result = func(argsArr[0], argsArr[1], argsArr[2], argsArr[3], argsArr[4], argsArr[5], argsArr[6], argsArr[7], argsArr[8], argsArr[9])

	if expected == result then
		print("<color=#44ff66><b>SUCCESS:</b> " + desc + "</color>")
	else
		print("<color=#ff4488><b>FAIL:</b> " + desc + "</color>")
		print("* Expected value to be: <color=#44ff66>" + expected + "</color>")
		print("* Received: <color=#ff4488>" + result + "</color>")
	end if
end function
