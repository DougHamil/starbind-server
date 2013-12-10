fs = require 'fs'
path = require 'path'
os = require 'os'
util = require '../util'

CONFIG = {}
try
  source = path.join process.cwd(), 'config.json'
  CONFIG = JSON.parse(fs.readFileSync(source, 'utf8'))
  CONFIG.__source = source
catch err
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


if not fs.existsSync path.join(CONFIG.STARBOUND_INSTALL_DIR)
  console.log "Searching for Starbound installation directory..."
  # Attempt to guess at the install directory
  guess = util.findStarboundPath os.platform(), os.arch()
  if guess?
    console.log "Found Starbound installation at #{guess}"
    CONFIG.STARBOUND_INSTALL_DIR = guess
    CONFIG.saveSync()
  else
    console.log "Unable to find Starbound installation directory, please manually set it in config.json"

module.exports = CONFIG
