CONFIG = require '../config'
Starbound = require '../../starbound'
fs = require 'fs'
spawn = require('child_process').spawn

exports.init = (app) ->
  app.get '/', (req, res) ->
    res.redirect '/admin'

  app.get '/admin/server/log', (req, res) ->
    res.json Starbound.log

  app.get '/admin/server/stop', (req, res) ->
    if Starbound.serverProcess?
      Starbound.serverProcess.kill()
      res.redirect '/admin'
    else
      res.send 400, 'Server not running'
  app.get '/admin/server/start', (req, res) ->
    if Starbound.serverProcess?
      res.send 400, 'Server already started'
    else
      serverScript = CONFIG.STARBOUND_INSTALL_DIR + "/" +CONFIG.PLATFORM + "/starbound_server"
      proc = spawn "#{serverScript}"
      proc.stderr.setEncoding 'utf8'
      proc.stdout.setEncoding 'utf8'
      proc.stderr.on 'data', (data) ->
        Starbound.log.unshift data
        if CONFIG.MAX_LOG_SIZE < Starbound.log.length
          Starbound.log.pop()

      proc.stdout.on 'data', (data) ->
        Starbound.log.unshift data
        if CONFIG.MAX_LOG_SIZE < Starbound.log.length
          Starbound.log.pop()

      proc.on 'close', (code) ->
        Starbound.serverProcess = null
      Starbound.serverProcess = proc
      res.redirect '/admin'

  app.get '/admin', (req, res) ->
    fs.readFile CONFIG.STARBOUND_INSTALL_DIR+"/assets/default_configuration.config", (err, data) ->
      if err
        res.send 500, err
      else
        res.render 'admin', {installFound:Starbound.repo?,status:{isRunning:Starbound.serverProcess?, log:Starbound.log},config:JSON.parse(data)}



