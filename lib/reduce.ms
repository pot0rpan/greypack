reduce = function(array, callback, initialValue)
  accumulator = null
  index = 0
  
  if initialValue then
    accumulator = initialValue
  else
    accumulator = array[0]
    index = index + 1
  end if

  while index < array.len
    accumulator = callback(accumulator, array[index], index, array)
    index = index + 1
  end while

  return accumulator
end function
