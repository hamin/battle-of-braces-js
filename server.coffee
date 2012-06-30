express = require 'express'
faye = require 'faye'
routes = require './routes'
app = module.exports = express.createServer()
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


registerPlayer = {
  incoming: (message, callback) ->
    if message.subscription == '/start_game'
      bayeux.getClient().publish '/start_game', {player: 'new'}
    return callback message
}


bayeux = new faye.NodeAdapter mount: '/faye', timeout: 45

bayeux.addExtension registerPlayer
bayeux.attach app

app.listen 3000, ->
  console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env