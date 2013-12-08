CONFIG = require './server/config'
express = require 'express'

Starbound = require './starbound'
AdminController = require './server/controllers/admin'
PropController = require './server/controllers/prop'
GitController = require './server/controllers/git'

sessionStore = new express.session.MemoryStore()

app = express()
app.use express.bodyParser()
app.use express.cookieParser()
app.use express.session({store:sessionStore, secret: CONFIG.SESSION_SECRET})
app.use express.static('public')
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'

Starbound.init (err) ->
  if not err?
    AdminController.init(app)
    PropController.init(app)
    GitController.init(app)
    console.log "Server listening on port #{CONFIG.PORT}"
    app.listen CONFIG.PORT
  else
    console.log "Error initializing Starbound server:"
    console.log err

