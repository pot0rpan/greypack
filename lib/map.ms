map = function(arr, callback)
	newArr = []
	i = 0

	for el in arr
		newArr.push(callback(el, i))
		i = i + 1
	end for
  
	return newArr
end function
