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
  # attrs: hue, score
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
    numPlayers = @players.length
    totalScore = @players.totalScore()
    netScore = 0
    @players.each ((player, i) ->
      score = player.get('score')
      startAngle = (netScore / totalScore) * 360
      endAngle = ((netScore + score) / totalScore) * 360
      hue = player.get('hue')

      path = @paper.path().attr
        fill: "hsb(#{hue}, 0.6, 1)"
        'stroke-width': 0
        arc: [300, 300, startAngle, endAngle, 100, 120]

      @paths.push path
      netScore += score
    ), this


setupRaphael = () ->
  paper = Raphael 'holder', 600, 600

  # taken from http://stackoverflow.com/a/9330739/358804
  paper.customAttributes.arc = (centerX, centerY, startAngle, endAngle, innerR, outerR) ->
    radians = Math.PI / 180
    largeArc = +(endAngle - startAngle > 180)
    outerX1 = centerX + outerR * Math.cos((startAngle - 90) * radians)
    outerY1 = centerY + outerR * Math.sin((startAngle - 90) * radians)
    outerX2 = centerX + outerR * Math.cos((endAngle - 90) * radians)
    outerY2 = centerY + outerR * Math.sin((endAngle - 90) * radians)
    innerX1 = centerX + innerR * Math.cos((endAngle - 90) * radians)
    innerY1 = centerY + innerR * Math.sin((endAngle - 90) * radians)
    innerX2 = centerX + innerR * Math.cos((startAngle - 90) * radians)
    innerY2 = centerY + innerR * Math.sin((startAngle - 90) * radians)

    path = [
      [ "M", outerX1, outerY1 ],
      [ "A", outerR, outerR, 0, largeArc, 1, outerX2, outerY2 ],
      [ "L", innerX1, innerY1 ],
      [ "A", innerR, innerR, 0, largeArc, 0, innerX2, innerY2 ],
      [ "z" ] ]

    path: path

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

  player1 = new Player(hue: '0.33', score: 2)
  player2 = new Player(hue: '0.66', score: 6)
  player3 = new Player(hue: '1', score: 4)

  players = new PlayersCollection [player1, player2, player3]
  console.log players.totalScore()

  goalCircle = new GoalCircle paper, players
  goalCircle.draw()












