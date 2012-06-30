client = new Faye.Client('/faye')

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
    if event.keyCode is 16
      shoot {x: curLeftPos+50, y: curTopPos-15}, false
      oppY = $('.opponent').offset().top + $('.opponent').height()
      client.publish '/fire', x: curLeftPos+50, y: oppY, oppClientId: clientId

    client.publish "/opponentPos", { curLeftPos: $(".me").offset().left }    
  
