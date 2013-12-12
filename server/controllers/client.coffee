CONFIG = require '../config'
Starbound = require '../../starbound'
os = require 'os'
rimraf = require 'rimraf'
ncp = require 'ncp'
path = require 'path'
temp = require 'temp'
util = require '../../util'
spawn = require('child_process').spawn
httpSyncClient = require('http-dir-sync').Client

getRemoteName = (host) ->
  return host.replace(/[^\w\s]/gi, '_')

synchronize = (remote, res) ->
  Starbound.repo.remote_fetch remote, (err) ->
    if err?
      console.log "FETCHING REMOTES: #{err}"
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

  # Launch the game
  app.get '/launch', (req, res) ->
    proc = Starbound.game.launch()
    if proc?
      res.send 200
    else
      res.send 500

  app.post '/sync', (req, res) ->
    host = req.body.host

    if not host?
      res.send 400, "Expected 'host'"
      return
    # Default to HTTP if no protocal is specified
    hostWithProtocol = host
    if host.indexOf('http://') isnt 0 and host.indexOf('https://') isnt 0
      hostWithProtocol = "http://"+host
    dirSyncUrl = "#{hostWithProtocol}/starbindsync"
    httpSyncClient Starbound.assetPath, dirSyncUrl, null, (err) ->
      if err?
        res.send 500, err
      else
        res.send 200
