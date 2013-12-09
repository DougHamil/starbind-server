fs = require 'fs'
path = require 'path'

CONFIG = {}
try
  source = path.join __dirname, '../config.json'
  CONFIG = JSON.parse(fs.readFileSync(source, 'utf8'))
  CONFIG.__source = source
catch err
  source = path.join __dirname, '../config.default.json'
  CONFIG = JSON.parse(fs.readFileSync(source, 'utf8'))
  CONFIG.__source = source

CONFIG.save = (cb) ->
  fs.writeFile CONFIG.__source, JSON.stringify(CONFIG, null, 2), (err) ->
    if err?
      console.log "Error saving config: #{err}"
    cb err

CONFIG.isServer = false
process.argv.forEach (val, index, array) ->
  if val == 'server'
    CONFIG.isServer = true

module.exports = CONFIG
