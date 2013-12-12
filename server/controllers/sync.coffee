CONFIG = require '../config'
Starbound = require '../../starbound'
httpsync = require 'http-dir-sync'
path = require 'path'

exports.init = (app, cb) ->
  # Create http sync server
  httpSyncServer = httpsync.Server(Starbound.assetPath, 'starbindsync')
  # Connect handler to server
  app.use httpSyncServer.handler

  # Merge all changes in the mod directory
  app.get '/merge', (req, res) ->
    Starbound.mergeMods httpSyncServer, (err) ->
      if err?
        res.send 500, err
      else
        res.send 200

  # Merge mods initially
  Starbound.mergeMods httpSyncServer, cb
