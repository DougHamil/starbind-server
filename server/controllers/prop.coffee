CONFIG = require '../config'
Starbound = require '../../starbound'
jsonpath = require('JSONPath').eval
fs = require 'fs'

exports.init = (app) ->

  app.post '/prop', (req, res) ->
    file = req.body.file
    prop = req.body.prop
    value = req.body.value

    if not file? or not prop? or not value?
      res.send 400, 'Expected file, prop and value'
      return

    path = Starbound.getAssetPath(file)
    fs.readFile path, (err, data) ->
      if err?
        res.send 500, err
      else
        try
          json = JSON.parse(data)
          props = prop.split '/'
          parent = json
          while props.length > 1
            parent = parent[props.pop()]
          parent[props.pop()] = value
          fs.writeFile path, JSON.stringify(json, null, 2), (err) ->
            if err?
              res.send 500, err
            else
              res.send 200, ""


  app.get '/prop', (req, res) ->
    file = req.query.file
    prop = req.query.prop

    if not file? or not prop?
      res.send 400, 'Expected file and prop'
      return

    path = Starbound.getAssetPath(file)
    fs.readFile path, (err, data) ->
      if err?
        res.send 500, err
      else
        try
          json = JSON.parse(data)
          console.log prop
          console.log jsonpath(json, prop)
          res.json jsonpath(json, prop)
        catch err
          res.send 500, err



