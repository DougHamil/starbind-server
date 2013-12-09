CONFIG = require '../config'
Starbound = require '../../starbound'
os = require 'os'
rimraf = require 'rimraf'
ncp = require 'ncp'
path = require 'path'
Git = require 'gift'
temp = require 'temp'

getRemoteName = (host) ->
  return host.replace(/[^\w\s]/gi, '_')

synchronize = (remote, res) ->
  Starbound.repo.remote_fetch remote, (err) ->
    if err?
      res.send 500, err
    else
      Starbound.repo.checkout "#{remote}/master", (err) ->
        if err?
          console.log err
          res.send 500, err
        else
          console.log "Successfully synchronized to #{remote}"
          res.send 200, "Done"

exports.init = (app) ->
  app.get '/', (req,res) ->
    res.render 'client', {installFound:Starbound.installFound}

  app.post '/sync', (req, res) ->
    host = req.body.host
    username = req.body.username
    password = req.body.password

    if not host? or not username? or not password?
      res.send 400, "Expected 'host', 'username' and 'password'"
      return

    repoUrl = "http://#{username}:#{password}@#{host}/starbound-server.git"

    remoteName = getRemoteName(host)
    console.log "Checking for current remotes..."
    Starbound.repo.remotes (err, remotes) ->
      if err?
        res.send 500, err
      else
        remotes = remotes.map (remote) -> remote.name
        console.log remotes
        if (remoteName + "/master") in remotes
          console.log "Remote #{remoteName} found, fetching latest data..."
          synchronize(remoteName, res)
        else
          console.log "Remote not found, adding remote for #{host}"
          Starbound.repo.remote_add remoteName, repoUrl, (err) ->
            if not err?
              synchronize(remoteName, res)
            else
              console.log err
              res.send 500, err
