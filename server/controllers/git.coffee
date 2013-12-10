CONFIG = require '../config'
Git = require 'gift'
GitServer = require '../git/server'
Starbound = require '../../starbound'
path = require 'path'

exports.init = (app) ->
  # Clients have read-only access to git server
  if CONFIG.CLIENT_LOGINS?
    users = CONFIG.CLIENT_LOGINS.map (user) -> {user:user, permissions:['R']}
  else
    users = []

# Server has read/write permission
  users.push {user: CONFIG.SERVER_LOGIN, permissions:['R', 'W']}
  gitDirPath = path.join Starbound.assetPath, '.git'
  gitServer = new GitServer('starbound-server.git', gitDirPath, users)

  # Route git requests to our Git server handler
  app.use (req, res, next) ->
    if req.path.indexOf('/starbound-server.git') == 0
      gitServer(req, res)
    else
      next()

  # Merge all changes in the mod directory
  app.get '/git/merge', (req, res) ->
    Starbound.mergeMods (err) ->
      if err?
        res.send 500, err
      else
        res.send 200, "Done"

  # Add a user login
  app.post '/git/user/add', (req, res) ->
    username = req.body.username
    password = req.body.password
    if not username? or not password?
      res.send 400, "Expected 'username' and 'password'"
    else
      CONFIG.CLIENT_LOGINS.push {username:username, password:password}
      CONFIG.save (err)->
        if err?
          res.send 500, err
        else
          res.send 200, ""

  # Remove a client login
  app.post '/git/user/delete', (req, res) ->
    username = req.body.username
    if not username?
      res.send 400, "Expected 'username'"
    else
      CONFIG.CLIENT_LOGINS = CONFIG.CLIENT_LOGINS.filter (a) -> a.username != username
      CONFIG.save (err) ->
        if err?
          res.send 500, err
        else
          res.send 200, ""

