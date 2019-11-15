filter = function(array, callback)
  newArr = []
  i = 0

  for el in array
    if callback(el, i) then newArr.push(el)
    i = i + 1
  end for

  return newArr
end function
