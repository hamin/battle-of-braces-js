client = new Faye.Client('/faye')

GOAL_CIRCLE_RADIUS = 265
GOAL_CIRCLE_WIDTH = 10

Player = Backbone.Model.extend(
  # attrs: id, angle, hue, score
  urlRoot: '/players'
  defaults:
    angle: 0
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
    fakeGoalRad = GOAL_CIRCLE_RADIUS - GOAL_CIRCLE_WIDTH
    @players.each ((player, i) ->
      hue = player.get 'hue'
      score = player.get 'score'
      startAngle = i * arcSize
      endAngle = startAngle + arcSize
      endAngle = 359 if endAngle is 360

      path = @paper.path().attr
        fill: "hsb(#{hue}, 0.6, 1)"
        'stroke-width': 0
        arc: [GOAL_CIRCLE_RADIUS, GOAL_CIRCLE_RADIUS, startAngle, endAngle, GOAL_CIRCLE_RADIUS - GOAL_CIRCLE_WIDTH, GOAL_CIRCLE_RADIUS]

      path2 = @paper.path().attr
        fill: "hsba(#{hue}, 1, 1, 0.1)"
        'stroke-width': 0
        arc: [GOAL_CIRCLE_RADIUS, GOAL_CIRCLE_RADIUS, startAngle, endAngle, fakeGoalRad - 20, fakeGoalRad]  

      @paths.push path
      netScore += score
    ), this


PADDLE_RADIUS = GOAL_CIRCLE_RADIUS - GOAL_CIRCLE_WIDTH - 10

class Paddle
  constructor: (@paper, @player) ->
    hue = @player.get 'hue'
    @path = @paper.path().attr
      fill: "hsb(#{hue}, 1, 1)"
      arc: this.getArc(@player)
    
    @player.on 'change:angle', this.onAngleChange, this

  getArc: (player) ->
    angle = @player.get 'angle'
    [GOAL_CIRCLE_RADIUS, GOAL_CIRCLE_RADIUS, angle, angle + 30, PADDLE_RADIUS - 10, PADDLE_RADIUS]

  onAngleChange: (model, newAngle) ->
    @path.animate
      arc: this.getArc(model), 500, 'linear'

# -----------------

setupRaphael = () ->
  paperSize = GOAL_CIRCLE_RADIUS * 2
  window.paper = Raphael 'holder', paperSize, paperSize

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

  currentUser = new Player hue: Math.random()
  currentUser.save()

  players = new PlayersCollection
  players.on 'add', (player) ->
    console.log 'num players: ', players.length
    new Paddle paper, player

  players.add currentUser
  players.fetch add: true # GET /players
  
  # Faye Add New PLayer
  client.subscribe "/new_player", (message) ->
    player = new Player(message)
    players.add player
    
  console.log players.totalScore()
  
  goalCircle = new GoalCircle paper, players
  goalCircle.draw()
  
  # Faye Sub - Update PLayer
  client.subscribe '/updatePlayer', (message) ->
    userId = message.id
    opponent = players.get(userId)
    if opponent
      opponent.set message
    else
      console.warn "player not found: #{userId}"
    
    
  # Arrow Button Bindings
  $('body').keydown (event) ->
    console.log "keyCode #{event.keyCode}"

    #left
    if event.keyCode is 37
      console.log "MOVING LEFT"
      currentUser.moveLeft()
    # right
    if event.keyCode is 39
      console.log "MOVING RIGHT"
      currentUser.moveRight()
  
    client.publish "/updatePlayer", currentUser.toJSON()
  
  
  
  
  # bouncyBall = paper.circle(GOAL_CIRCLE_RADIUS, GOAL_CIRCLE_RADIUS, 10).attr("gradient", "r#293df7-#1e2dbd")
  # bouncyBall.animate { cy: (GOAL_CIRCLE_RADIUS * 2) - GOAL_CIRCLE_WIDTH }, 500, '>'
  # 
  # bouncyBall.onAnimation () ->
  #   collidingElems = paper.getElementsByPoint( bouncyBall.attr().cx, bouncyBall.attr().cy )
  #   console.log "THESE ARE COLLIDING ELEMENTS"
  #   console.log collidingElems
  #   if collidingElems.length > 0 and (collidingElems[0] isnt bouncyBall)
  #     hitObject = collidingElems[0]
  #     
  #     bouncyBall.animate { cy: hitObject.attr().cy }, 500, '>'





