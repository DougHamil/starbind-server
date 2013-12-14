fs = require 'fs'
path = require 'path'
os = require 'os'

CONFIG = {}
try
  source = path.join process.cwd(), 'config.json'
  CONFIG = JSON.parse(fs.readFileSync(source, 'utf8'))
  CONFIG.__source = source
catch err
  console.log "Error parsing config.json: #{err}"
  source = path.join process.cwd(), 'config.default.json'
  CONFIG = JSON.parse(fs.readFileSync(source, 'utf8'))
  CONFIG.__source = source

CONFIG.save = (cb) ->
  source = CONFIG.__source
  isServer = CONFIG.isServer
  delete CONFIG.__source
  delete CONFIG.isServer
  fs.writeFile path.join(process.cwd(), 'config.json'), JSON.stringify(CONFIG, null, 2), (err) ->
    CONFIG.__source = source
    CONFIG.isServer = isServer
    if err?
      console.log "Error saving config: #{err}"
    cb err

CONFIG.saveSync = ->
  source = CONFIG.__source
  isServer = CONFIG.isServer
  delete CONFIG.__source
  delete CONFIG.isServer
  fs.writeFileSync path.join(process.cwd(), 'config.json'), JSON.stringify(CONFIG, null, 2)
  CONFIG.__source = source
  CONFIG.isServer = isServer

CONFIG.isServer = false
process.argv.forEach (val, index, array) ->
  if val == 'server'
    CONFIG.isServer = true

module.exports = CONFIG
