util = require './util'
CONFIG = require './config'
path = require 'path'
spawn = require('child_process').spawn
fs = require 'fs'
os = require 'os'

module.exports =
  init: (gamePath) ->
    @path = gamePath
    @logs = []
    @config = @getConfigSync()

  getConfigSync: ->
    configPath = if fs.existsSync(path.join(@path, 'starbound.config')) then path.join(@path, 'starbound.config') else path.join(CONFIG.STARBOUND_INSTALL_DIR, 'assets', 'default_configuration.config')
    try
      data = fs.readFileSync configPath, 'utf8'
      if data?
        return JSON.parse(data)
      else
        return null
    catch err
      return null

  launch: ->
    exe = util.getFullExePath()
    if exe?
      @gameProcess = spawn(exe)
      return @gameProcess
    else
      return null

  killServer: ->
    if @serverProcess?
      console.log "Killing for #{os.platform()}"
      # Handle possible script starting a child process in same process group
      if os.platform() isnt 'win32'
        console.log @serverProcess.pid
        console.log process.kill -@serverProcess.pid
      else
        @serverProcess.kill()

  launchServer: ->
    exe = util.getFullServerExePath()
    console.log exe
    if exe?
      @serverProcess = spawn(exe, [], {detached:(os.platform() isnt 'win32')})
      if @serverProcess?
        @serverProcess.stderr.setEncoding 'utf8'
        @serverProcess.stdout.setEncoding 'utf8'
        @serverProcess.stdout.on 'data', (data) =>
          type = 'out'
          if data.toString().indexOf('Error:') == 0
            type = 'err'
          @log(type, data)
        @serverProcess.stderr.on 'data', (data) =>
          @log('err', data)
        @serverProcess.on 'exit', =>
          delete @serverProcess
        @serverProcess.on 'close', =>
          delete @serverProcess

      return @serverProcess
    else
      return null

  log:(type, data) ->
    @logs.unshift {type:type, message:data.toString()}
    if @logs.length > CONFIG.MAX_LOGS
      @logs.pop()
