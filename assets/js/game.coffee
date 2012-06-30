client = new Faye.Client('/faye')

setupRaphael = () ->
  paper = Raphael 'holder', 600, 600

  paper.customAttributes.arc = (value, total, R) ->
    alpha = 360 / total * value
    a = (90 - alpha) * Math.PI / 180
    x = 300 + R * Math.cos(a)
    y = 300 - R * Math.sin(a)
    color = "hsb(".concat(Math.round(R) / 200, ",", value / total, ", .75)")
    path = undefined
    if total is value
      path = [ [ "M", 300, 300 - R ], [ "A", R, R, 0, 1, 1, 299.99, 300 - R ] ]
    else
      path = [ [ "M", 300, 300 - R ], [ "A", R, R, 0, +(alpha > 180), 1, x, y ] ]
    path: path
    stroke: color

  return paper


$(document).ready () ->
  # Faye Sub - Opponent Position
  client.subscribe "/opponentPos", (message) ->
    console.log "Opponent Moved!"
  
  # Faye Sub - Fire
  client.subscribe "/fire", (message) ->
    if message.oppClientId isnt clientId
      shoot {x: message.x, y: message.y}, true
      
  
  # Arrow Button Bindings
  $('body').keydown (event) ->
    console.log "keyCode #{event.keyCode}"
    curLeftPos = $(".me").offset().left
    curTopPos = $(".me").offset().top

    offset = 50
    #left
    if event.keyCode is 37
      updateDivPosition "me", curLeftPos - offset
    # right
    if event.keyCode is 39
      updateDivPosition "me", curLeftPos + offset
    # Spacebar  
    if event.keyCode is 16
      shoot {x: curLeftPos+50, y: curTopPos-15}, false
      oppY = $('.opponent').offset().top + $('.opponent').height()
      client.publish '/fire', x: curLeftPos+50, y: oppY, oppClientId: clientId

    client.publish "/opponentPos", { curLeftPos: $(".me").offset().left }    
  
  paper = setupRaphael()

  paper.path().attr
    stroke: '#ff0'
    'stroke-width': 14
    arc: [40, 60, 100]
