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





Player = Backbone.Model.extend(
  # attrs: score
)

PlayersCollection = Backbone.Collection.extend(
  model: Player

  totalScore: () ->
    this.reduce ((sum, player) -> sum + player.get('score')), 0
)


class GoalCircle
  constructor: (@paper, @players) ->
    @paths = []

  draw: () ->
    totalScore = @players.totalScore()
    @players.each ((player, i) ->
      path = @paper.path().attr
        stroke: '#ff0'
        'stroke-width': 14
        arc: [player.get('score'), totalScore, 100 + (i * 10)]

      @paths.push path
    ), this



setupRaphael = () ->
  paper = Raphael 'holder', 600, 600

  paper.customAttributes.arc = (value, total, radius) ->
    alpha = 360 / total * value
    a = (90 - alpha) * Math.PI / 180
    x = 300 + radius * Math.cos(a)
    y = 300 - radius * Math.sin(a)
    color = "hsb(".concat(Math.round(radius) / 200, ",", value / total, ", .75)")
    path = undefined
    if total is value
      path = [ [ "M", 300, 300 - radius ], [ "A", radius, radius, 0, 1, 1, 299.99, 300 - radius ] ]
    else
      path = [ [ "M", 300, 300 - radius ], [ "A", radius, radius, 0, +(alpha > 180), 1, x, y ] ]
    path: path
    stroke: color

  return paper


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
  
  paper = setupRaphael()

  player1 = new Player
  player1.set 'score', 6
  player2 = new Player
  player2.set 'score', 2

  players = new PlayersCollection [player1, player2]
  console.log players.totalScore()

  goalCircle = new GoalCircle paper, players
  goalCircle.draw()












