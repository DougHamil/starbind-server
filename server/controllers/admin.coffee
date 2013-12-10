CONFIG = require '../config'
Starbound = require '../../starbound'
fs = require 'fs'
spawn = require('child_process').spawn

exports.init = (app) ->
  app.get '/', (req, res) ->
    res.redirect '/admin'

  app.get '/admin', (req, res) ->
    fs.readFile CONFIG.STARBOUND_INSTALL_DIR+"/assets/default_configuration.config", (err, data) ->
      if err
        res.send 500, err
      else
        res.render 'admin', {installFound:Starbound.repo?,status:{isRunning:Starbound.serverProcess?, log:Starbound.log},config:JSON.parse(data)}




