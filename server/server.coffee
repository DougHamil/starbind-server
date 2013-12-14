CONFIG = require './config'
express = require 'express'
open = require 'open'
Security = require './security'
path = require 'path'

Starbound = require './starbound'
AdminController = require './controllers/admin'
PropController = require './controllers/prop'
ClientController = require './controllers/client'
SyncController = require './controllers/sync'

sessionStore = new express.session.MemoryStore()

if not CONFIG.isServer and not CONFIG.SESSION_SECRET?
  CONFIG.SESSION_SECRET = 'STARBIND_CLIENT_SESSION'

app = express()
app.use express.bodyParser()
app.use express.cookieParser()
app.use express.session({store:sessionStore, secret: CONFIG.SESSION_SECRET})
app.use express.static(__dirname + '/public')
app.use Security.authHandler
app.set 'views', path.resolve(__dirname,'../views')
app.set 'view engine', 'jade'

startServer = (openBrowser) ->
  server = null
  if Security.httpsCredentials?
    server = https.createServer Security.httpsCredentials, app
  else
    server = http.createServer app
  server.listen(CONFIG.PORT)
  if openBrowser
    if Security.httpsCredentials?
      open('https://localhost:'+CONFIG.PORT)
    else
      open('http://localhost:'+CONFIG.PORT)

Starbound.init (err) ->
  if not err?
    if CONFIG.isServer
      console.log "Running in SERVER mode."
      AdminController.init(app)
      PropController.init(app)
      SyncController.init app, (err) ->
        console.log "Server listening on port #{CONFIG.PORT}"
        app.listen CONFIG.PORT
    else
      console.log "Running in CLIENT mode."
      ClientController.init(app)
      console.log "Server listening on port #{CONFIG.PORT}"
      app.listen CONFIG.PORT, 'localhost', () ->
        open('http://localhost:'+CONFIG.PORT)
  else
    console.log "Error initializing Starbound server:"
    console.log err

