CONFIG = require '../config'
Git = require 'gift'
GitServer = require '../git/server'
Starbound = require '../../starbound'
path = require 'path'

# Clients have read-only access to git server
users = CONFIG.CLIENT_LOGINS.map (user) -> {user:user, permissions:['R']}
# Server has read/write permission
users.push {user: CONFIG.SERVER_LOGIN, permissions:['R', 'W']}

repoConfig =
  name: 'assets/'
  anonRead:false
  users: users

gitDirPath = path.join Starbound.assetPath, '.git'
console.log "DIR PATH: #{gitDirPath}"
gitServer = new GitServer('starbound-server.git', gitDirPath, CONFIG.REPO_PORT, users)

exports.init = (app) ->
  # Return all available branches
  app.get '/git/mods', (req, res) ->
    Starbound.getBranches (err, branches) ->
      if err?
        res.send 500, err
      else
        res.json branches

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

