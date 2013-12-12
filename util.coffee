CONFIG = require './server/config'
path = require 'path'
fs = require 'fs'
os = require 'os'
spawn = require('child_process').spawn

if not process.env.HOME?
  process.env.HOME = '/'

ARCHES =
  win32:
    x64:
      exePath: 'win32'
      exe: 'starbound.exe'
      server_exe: 'starbound_server.exe'
      dirs:[
        '/Program Files (x86)/Steam/SteamApps/common/Starbound',
        '/Program Files/Steam/SteamApps/common/Starbound'
      ]
    ia32:
      exePath: 'win32'
      exe: 'starbound.exe'
      server_exe: 'starbound_server.exe'
      dirs:[
        '/Program Files (x86)/Steam/SteamApps/common/Starbound',
        '/Program Files/Steam/SteamApps/common/Starbound'
      ]
    x86:
      exePath: 'win32'
      exe: 'starbound.exe'
      server_exe: 'starbound_server.exe'
      dirs:[
        '/Program Files (x86)/Steam/SteamApps/common/Starbound',
        '/Program Files/Steam/SteamApps/common/Starbound'
      ]
  linux:
    x64:
      exePath: 'linux64'
      exe: 'launch_starbound.sh'
      server_exe: 'launch_starbound_server.sh'
      dirs:[
        path.join(process.env.HOME, '.steam/steam/SteamApps/common/Starbound'),
        '/home/steam/SteamApps/common/Starbound'
      ]
    x86:
      exePath: 'linux32'
      exe: 'launch_starbound.sh'
      server_exe: 'launch_starbound_server.sh'
      dirs:[
        path.join(process.env.HOME, '.steam/steam/SteamApps/common/Starbound'),
        '/home/steam/SteamApps/common/Starbound'
      ]
  darwin:
    x64:
      exePath: 'Starbound.app/Contents/MacOS'
      exe: 'starbound'
      server_exe: 'starbound_server'
      dirs:[
        path.join(process.env.HOME, 'Library/Application Support/Steam/SteamApps/common/Starbound')
      ]
    x86:
      exePath: 'Starbound.app/Contents/MacOS'
      exe: 'starbound'
      server_exe: 'starbound_server'
      dirs: [
        path.join(process.env.HOME, 'Library/Application Support/Steam/SteamApps/common/Starbound')
      ]

module.exports =
  getServerExe: ->
    return @getPlatformProp('server_exe')
  getExe: ->
    return @getPlatformProp('exe')
  getExePath: ->
    return @getPlatformProp('exePath')

  getPlatformProp: (prop) ->
    plat = os.platform()
    arch = os.arch()
    if ARCHES[plat]? and ARCHES[plat][arch]?
      return ARCHES[plat][arch][prop]
    return null

  getFullServerExePath: ->
    exe = @getServerExe()
    exePath = @getExePath()
    installPath = CONFIG.STARBOUND_INSTALL_DIR
    console.log installPath
    if exe? and installPath? and exePath?
      fullPath = path.join installPath, exePath, exe
      return fullPath
    return null

  getFullExePath: ->
    exe = @getExe()
    exePath = @getExePath()
    installPath = CONFIG.STARBOUND_INSTALL_DIR
    if exe? and installPath?
      fullPath = path.join installPath, exePath, exe
      return fullPath
    return null

  verifyStarboundInstallPath: ->
    if not CONFIG.STARBOUND_INSTALL_DIR? or not fs.existsSync path.join(CONFIG.STARBOUND_INSTALL_DIR)
      console.log "Searching for Starbound installation directory..."
      # Attempt to guess at the install directory
      guess = @findStarboundInstallPath()
      if guess?
        console.log "Found Starbound installation at #{guess}"
        CONFIG.STARBOUND_INSTALL_DIR = guess
        CONFIG.saveSync()
      else
        console.log "Unable to find Starbound installation directory, please manually set it in config.json"

  findStarboundInstallPath: ->
    guesses = @getPlatformProp('dirs')
    if guesses?
      for guess in guesses
        guess = path.join guess
        if fs.existsSync guess
          return guess
    return null
