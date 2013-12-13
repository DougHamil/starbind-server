CONFIG = require '../config'
Starbound = require '../starbound'
fs = require 'fs'
spawn = require('child_process').spawn

exports.init = (app) ->
  app.get '/', (req, res) ->
    res.redirect '/admin'

  app.get '/admin/mods/index', (req, res) ->
    res.json Starbound.mods.index

  app.get '/admin/server/logs', (req, res) ->
    res.json Starbound.game.logs

  app.get '/admin/server/start', (req, res) ->
    proc = Starbound.game.launchServer()
    if proc?
      res.send 200
    else
      res.send 500
  app.get '/admin/server/stop', (req, res) ->
    Starbound.game.killServer()
    res.send 200

  app.get '/admin', (req, res) ->
    res.render 'admin', {installFound:Starbound.repo?,status:{isRunning:Starbound.game.serverProcess?, log:Starbound.log},config:Starbound.game.config}

  app.get '/login', (req, res) ->
    loginFound = CONFIG.ADMIN_USERNAME? and CONFIG.ADMIN_USERNAME isnt '' and CONFIG.ADMIN_PASSWORD? and CONFIG.ADMIN_PASSWORD isnt ''
    res.render 'login', {loginFound:loginFound}

  app.post '/login', (req, res) ->
    user = req.body.username
    pass = req.body.password
    if CONFIG.ADMIN_USERNAME is user and CONFIG.ADMIN_PASSWORD is pass
      req.session.loggedIn = true
      res.redirect '/'
    else
      res.render 'login', {failed:true, loginFound:true}

  app.get '/logout', (req, res) ->
    delete req.session.loggedIn
    res.redirect '/login'



