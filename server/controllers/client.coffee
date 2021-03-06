CONFIG = require '../config'
Starbound = require '../starbound'
os = require 'os'
rimraf = require 'rimraf'
ncp = require 'ncp'
path = require 'path'
util = require '../util'
spawn = require('child_process').spawn
httpSyncClient = require('http-dir-sync').Client

getRemoteName = (host) ->
  return host.replace(/[^\w\s]/gi, '_')

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
    console.log dirSyncUrl
    httpSyncClient Starbound.assetPath, dirSyncUrl, null, (err) ->
      if err?
        res.send 500, err
      else
        res.send 200
