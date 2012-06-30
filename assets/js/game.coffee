client = new Faye.Client('/faye')


Player = Backbone.Model.extend(
  urlRoot: '/players'
  defaults:
    angle: 0
    hue: 0.5
    score: 0
  moveLeft: () ->
    @set('angle', @get('angle') + 20 )
  moveRight: () ->
    @set('angle', @get('angle') - 20 )    
)

PlayersCollection = Backbone.Collection.extend(
  model: Player
  url: '/players'

  totalScore: () ->
    this.reduce ((sum, player) -> sum + player.get('score')), 0
)

# ----- Views -------

class GoalCircle
  constructor: (@paper, @players) ->
    @paths = []

  draw: () ->
    numPlayers = @players.length
    arcSize = 360 / numPlayers
    netScore = 0
    @players.each ((player, i) ->
      hue = player.get 'hue'
      score = player.get 'score'
      startAngle = i * arcSize
      endAngle = startAngle + arcSize
      endAngle = 359 if endAngle is 360

      path = @paper.path().attr
        fill: "hsb(#{hue}, 0.6, 1)"
        'stroke-width': 0
        arc: [300, 300, startAngle, endAngle, 100, 120]

      @paths.push path
      netScore += score
    ), this


class Paddle
  constructor: (@paper, @player) ->
    hue = @player.get 'hue'
    @path = @paper.path().attr
      fill: "hsb(#{hue}, 1, 1)"
      arc: this.getArc(@player)
    
    @player.on 'change:angle', this.onAngleChange, this

  getArc: (player) ->
    angle = @player.get 'angle'
    [300, 300, angle, angle + 30, 80, 90]

  onAngleChange: (model, newAngle) ->
    @path.animate
      arc: this.getArc(model), 500, '>'

# -----------------

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
  # addPlayer('me')
  # yourPlayer = $('.me')
  
  paper = setupRaphael()

  # dummy data
  currentUser = new Player
  currentUser.save()

  players = new PlayersCollection
  players.on 'add', (player) ->
    new Paddle paper, player
  
  players.add currentUser
  players.fetch() # GET /players
  
  # Faye Add New PLayer
  client.subscribe "/new_player", (message) ->
    player = new Player(message)
    players.add player
    
  console.log players.totalScore()
  
  goalCircle = new GoalCircle paper, players
  goalCircle.draw()
  
  # Faye Sub - Update PLayer
  client.subscribe '/updatePlayer', (message) ->
    opponent = players.get(message.id)
    opponent.set(message)
    
    
  # Arrow Button Bindings
  $('body').keydown (event) ->
    console.log "keyCode #{event.keyCode}"
    curLeftPos = yourPlayer.offset().left
    curTopPos = yourPlayer.offset().top
  
    offset = 50
    #left
    if event.keyCode is 37
      console.log "MOVING LEFT"
      currentUser.moveLeft()
    # right
    if event.keyCode is 39
      console.log "MOVING RIGHT"
      currentUser.moveRight()
  
    client.publish "/updatePlayer", currentUser.toJSON()
    





