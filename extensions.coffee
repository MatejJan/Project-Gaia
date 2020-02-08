THREE.Color::setIntegerRGB = (rOrObject, g, b) ->
  if _.isObject rOrObject
    r = rOrObject.r
    g = rOrObject.g
    b = rOrObject.b

  else
    r = rOrObject

  @setRGB(r / 255, g / 255, b / 255)
