CONFIG = require './config'
util = require './util'
mods = require './mods'
game = require './game'
path = require 'path'
fs = require 'fs'
unzip = require 'unzip'
rimraf = require 'rimraf'
ncp = require 'ncp'
os = require 'os'
_ = require 'underscore'
temp = require 'temp'
temp.track()

MOD_INSTALL_DIR = 'starbind_mods'

util.verifyStarboundInstallPath()

repoPath = path.join CONFIG.STARBOUND_INSTALL_DIR, MOD_INSTALL_DIR
realAssetPath = path.join CONFIG.STARBOUND_INSTALL_DIR, "assets"
gamePath = path.join CONFIG.STARBOUND_INSTALL_DIR, util.getExePath()

console.log "Starbound game path set to: #{gamePath}"

game.init(gamePath)

module.exports =
  game:game
  mods:mods
  serverProcess: null
  log:[]
  modPath: path.resolve(process.cwd(), '../mods')
  gamePath:gamePath
  assetPath: repoPath
  realAssetPath: realAssetPath
  installFound:false
  getAssetPath: (prop) ->
    return path.join @assetPath, prop
  getBranches: (cb) ->
    @repo.branches cb
  addModsDirToBootstrap: () ->
      data = fs.readFileSync(path.join(@gamePath, "bootstrap.config"), 'utf8')
      if data?
        bootstrap = JSON.parse(data)
        changed = false
        if "../assets" in bootstrap.assetSources
          if "../#{MOD_INSTALL_DIR}" not in bootstrap.assetSources
            bootstrap.assetSources.push "../#{MOD_INSTALL_DIR}"
            changed = true
        else if "../../../assets" in bootstrap.assetSources
          if "../../../#{MOD_INSTALL_DIR}" not in bootstrap.assetSources
            bootstrap.assetSources.push "../../../#{MOD_INSTALL_DIR}"
            changed = true
        if changed
          console.log "Added #{MOD_INSTALL_DIR} to #{path.join(@gamePath, "bootstrap.config")}."
          fs.writeFileSync path.join(@gamePath, "bootstrap.config"), JSON.stringify(bootstrap, null, 2)

  mergeMods: (httpSyncServer, cb) ->
    # Extract all mods to the asset path (it will clear it out first)
    @mods.extractTo @assetPath, (err) =>
      if err?
        cb err
      else
        # Update the manifest for our file server
        httpSyncServer.update cb

  init: (cb) ->
    @installFound = fs.existsSync(CONFIG.STARBOUND_INSTALL_DIR)
    if not fs.existsSync(@modPath)
      console.log "Creating mod package directory at #{@modPath}"
      fs.mkdirSync @modPath
    if @installFound
      @addModsDirToBootstrap()
    if CONFIG.isServer
      @mods.init @modPath, @realAssetPath, cb
    else
      cb null

