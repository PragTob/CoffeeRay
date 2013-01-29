NUMBER_OF_WORKERS = 4

class Raytracer
    constructor: (@target, @backgroundColor, @viewport) ->
        @traceables = []
        @lights = []
        @pixelsProcessed = 0
        @totalPixels = (@target.width + 1) * (@target.height + 1)
        @createActors()
        
    createActors: ->
        @actors = []
        for i in [0...NUMBER_OF_WORKERS]
            @actors[i] = new Worker('traceWebWorker.js')
            @actors[i].addEventListener('message', -> console.log 'foo bar', false)#@drawPixel
            @actors[i].onerror = (event)-> console.log 'worker error: ' + event.message

    drawPixel: (data)->
        @target.setPixel(data.x, data.y, data.color)
        @pixelsProcessed++
        console.log @pixelsProcessed
        @target.finishedRendering() if @pixelsProcessed >= @totalPixels
    
    addTraceable: (object) -> 
        @traceables.push object
    
    addLightSource: (light) ->
        @lights.push light
    
    render: ->
        i = 0 
        @processPixel(x, y, (i++ % NUMBER_OF_WORKERS)) for x in [0..@target.width] for y in [0..@target.height]

    processPixel: (x, y, i) ->
        args =
            x: x
            y: y
            traceables: @traceables
            lights: @lights
            height: @target.height
            width: @target.width
        @actors[i].postMessage(args)