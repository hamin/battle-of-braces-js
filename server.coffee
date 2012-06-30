express = require 'express'
_= require 'underscore'
faye = require 'faye'
routes = require './routes'
app = module.exports = express.createServer()

playersById = {}
players = []

app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "ejs"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('connect-assets')()
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", routes.index
app.get "/game", routes.game

app.post '/players', (req, res) ->
  id = players.length + 1
  player = {id: id}
  playersById[id] = player
  players.push player
  
  # Let other PPl know via Faye
  bayeux.getClient().publish '/new_player', player
  
  res.send(
    player
  )
  
app.get "/players", (req, res) ->
  res.send players  



registerPlayer = {
  incoming: (message, callback) ->
    # if message.subscription == '/start_game'
    return callback message
}


bayeux = new faye.NodeAdapter mount: '/faye', timeout: 45

# bayeux.addExtension registerPlayer
bayeux.attach app

app.listen 3000, ->
  console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env