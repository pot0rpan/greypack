includes = function(value, array)
  for el in array
    if el == value then return true
  end for
  
  return false
end function
