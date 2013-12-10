path = require 'path'
fs = require 'fs'
os = require 'os'
spawn = require('child_process').spawn

ARCHES =
  win32:
    x64:
      exe: 'starbound.exe'
      dirs:[
        '/Program Files (x86)/Steam/SteamApps/common/Starbound',
        '/Program Files/Steam/SteamApps/common/Starbound'
      ]
    x86:
      exe: 'starbound.exe'
      dirs:[
        '/Program Files (x86)/Steam/SteamApps/common/Starbound',
        '/Program Files/Steam/SteamApps/common/Starbound'
      ]
  linux:
    x64:
      exe: 'launch_starbound.sh'
      dirs:[
        path.join(process.env.HOME, '.steam/steam/SteamApps/common/Starbound'),
        '/home/steam/SteamApps/common/Starbound'
      ]
    x86:
      exe: 'launch_starbound.sh'
      dirs:[
        path.join(process.env.HOME, '.steam/steam/SteamApps/common/Starbound'),
        '/home/steam/SteamApps/common/Starbound'
      ]
  darwin:
    x64:
      exe: 'starbound'
      dirs:[
        path.join(process.env.HOME, 'Library/Application Support/Steam/SteamApps/common/Starbound')
      ]
    x86:
      exe: 'starbound'
      dirs: [
        path.join(process.env.HOME, 'Library/Application Support/Steam/SteamApps/common/Starbound')
      ]

module.exports =
  launchGame: (gamePath) ->
    plat = os.platform()
    arch = os.arch()
    if ARCHES[plat]? and ARCHES[plat][arch]?
      exe = ARCHES[plat][arch].exe
      if exe?
        pathToGame = path.join(gamePath, exe)
        gameExe = spawn(pathToGame)
        return null
    return 'Unknown platform/arch'

  findStarboundPath: (os, arch) ->
    console.log "Trying to find install directory for #{os} #{arch}"
    if ARCHES[os]?
      guesses = ARCHES[os][arch]
      if guesses?
        for guess in guesses.dirs
          guess = path.join guess
          if fs.existsSync guess
            return guess
    return null
