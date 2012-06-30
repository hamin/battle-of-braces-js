client = new Faye.Client('/faye')

client.subscribe "/start_game", (message) ->
  addPlayer('opponent')


addPlayer = (playerType) ->
  playerId = $('#players').children().size() + 1
  if playerType is 'me'
    $("<div id='op-#{playerId}' class='me player'>THIS IS ME #{playerId}</div>").appendTo('#players')
  else
    $("<div id='op-#{playerId}' class='opponent player'>Opponent #{playerId}</div>").appendTo('#players');  	
    
updateDivPosition = (divName,newPosition) -> 
  newPosition = Math.max 13, newPosition
  newPosition = Math.min 600, newPosition
  
  console.log "newPosition = #{newPosition}"
  $("##{divName}").offset left: newPosition
  
$(document).ready () ->
  # Add YOUR Player
  addPlayer('me')
  yourPlayer = $('.me')
  
  # Faye Sub - Opponent Position
  client.subscribe "/opponentPos", (message) ->
    console.log "Opponent Moved!"
    updateDivPosition message.playerId, message.curLeftPos
  
  # Faye Sub - Fire
  client.subscribe "/fire", (message) ->
    if message.oppClientId isnt clientId
      shoot {x: message.x, y: message.y}, true
      
  
  # Arrow Button Bindings
  $('body').keydown (event) ->
    console.log "keyCode #{event.keyCode}"
    curLeftPos = yourPlayer.offset().left
    curTopPos = yourPlayer.offset().top

    offset = 50
    #left
    if event.keyCode is 37
      updateDivPosition yourPlayer.attr('id'), curLeftPos - offset
    # right
    if event.keyCode is 39
      updateDivPosition yourPlayer.attr('id'), curLeftPos + offset
    # Spacebar  
    if event.keyCode is 16
      shoot {x: curLeftPos+50, y: curTopPos-15}, false
      oppY = $('.opponent').offset().top + $('.opponent').height()
      client.publish '/fire', x: curLeftPos+50, y: oppY, oppClientId: clientId

    client.publish "/opponentPos", { curLeftPos: yourPlayer.offset().left, playerId: yourPlayer.attr('id') }    
  
