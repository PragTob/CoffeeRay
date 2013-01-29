importScripts('ray.js', 'phongmodel.js', 'viewport.js')

workerObject =
  processPixel: (x, y) ->
    color = @determineColorAt x,y
    result =
      x:      x
      y:      y
      color:  color
    console.log 'mutti'
    return result

  determineColorAt: (x, y) ->
    ray = @viewport.constructRayForPixel(x, y)
    closestHit = @findIntersection(ray)

    if closestHit?
      @determineHitColor closestHit
    else
      @backgroundColor

  findIntersection: (ray) ->
    findFunc = (current, next) ->
      test = next.testIntersection ray
      return test if test?.distance < (current?.distance ? Infinity)
      current

    _.foldl @traceables, findFunc, null

  determineHitColor: (closestHit) ->
    phongModel = new PhongModel(closestHit)
    _.each @lights, (light) =>
      @calculateLighting light, phongModel
    phongModel.getColor()

  calculateLighting: (light, phongModel) ->
    lightVector = light.position.subtract phongModel.targetPosition
    lightDistance = lightVector.length()

    # This has the same effect as calling normalize, but we save
    # one length calculation since the length is already known.
    lightVector = lightVector.multiplyScalar(1.0 / lightDistance)
    lightRay = new Ray(phongModel.targetPosition, lightVector)

    unless @checkIfInShadow lightRay, lightDistance
      phongModel.contributeLight lightVector, light

  checkIfInShadow: (ray, lightDistance) ->
    _.any @traceables, (each) ->
      test = each.testIntersection ray
      test? and test.distance < lightDistance


self.onmessage = (data)->
  workerObject.viewport =  Viewport.defaultViewport(data.width, data.height)
  workerObject.traceables = data.traceables
  workerObject.lights = data.lights
  result = workerObject.processPixel data.x, data.y
  self.postMessage(result)
