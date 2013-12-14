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
minify = require('./minify').minify
temp.track()

BOOTSTRAP_BACKUP_FILE = 'backup.bootstrap.config'
MOD_INSTALL_DIR = 'starbind_mods'

util.verifyStarboundInstallPath()

repoPath = path.join CONFIG.STARBOUND_INSTALL_DIR, MOD_INSTALL_DIR
realAssetPath = path.join CONFIG.STARBOUND_INSTALL_DIR, "assets"
gamePath = path.join CONFIG.STARBOUND_INSTALL_DIR, util.getExePath()

console.log "Starbound game path set to: #{gamePath}"

game.init(gamePath)

copyFileSync = (srcFile, destFile) ->
  BUF_LENGTH = 64*1024
  buff = new Buffer(BUF_LENGTH)
  fdr = fs.openSync(srcFile, 'r')
  fdw = fs.openSync(destFile, 'w')
  bytesRead = 1
  pos = 0
  while bytesRead > 0
    bytesRead = fs.readSync(fdr, buff, 0, BUF_LENGTH, pos)
    fs.writeSync(fdw,buff,0,bytesRead)
    pos += bytesRead
  fs.closeSync(fdr)
  fs.closeSync(fdw)

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

  resetBootstrap: ->
    bsFile = path.join(@gamePath, 'bootstrap.config')
    bakFile = path.join(@gamePath, BOOTSTRAP_BACKUP_FILE)
    if fs.existsSync(bakFile)
      fs.unlinkSync bsFile
      copyFileSync bakFile, bsFile
      fs.unlinkSync bakFile

  isModsDirInBootstrap: (bs) ->
    if "../assets" in bs.assetSources and "../#{MOD_INSTALL_DIR}" in bs.assetSources
      return true
    else if "../../../assets" in bs.assetSources and "../../../#{MOD_INSTALL_DIR}" in bs.assetSources
      return true
    return false

  backupBootstrap: (cb) ->
    bsFile = path.join(@gamePath, 'bootstrap.config')
    bakFile = path.join(@gamePath, BOOTSTRAP_BACKUP_FILE)

    backup = (bootstrap)->
      if not bootstrap?
        bootstrap = JSON.parse(minify(fs.readFileSync(bsFile, 'utf8')))
      # Backup this bootstrap
      fs.createReadStream(bsFile).pipe(fs.createWriteStream(bakFile))
        .on 'close', ->
          cb null, bootstrap
        .on('error', cb)

    # If the backup already exists that means we probably crashed
    if fs.existsSync bakFile
      # Read the data file
      data = fs.readFileSync(bsFile, 'utf8')
      bootstrap = JSON.parse(minify(data))
      # If starbind mods dir is in bootstrap, then we definitely crashed
      if @isModsDirInBootstrap(bootstrap)
        cb null, bootstrap
      else
        fs.unlinkSync bakFile
        backup(bootstrap)
    else
      backup()

  setupBootstrap: (cb) ->
    @backupBootstrap (err, bootstrap) =>
      if err?
        cb err
      else
        if "../assets" in bootstrap.assetSources
          bootstrap.assetSources = ['../assets', "../#{MOD_INSTALL_DIR}"]
        else if "../../../assets" in bootstrap.assetSources
          bootstrap.assetSources = ['../../../assets',  "../../../#{MOD_INSTALL_DIR}"]
        console.log "Added #{MOD_INSTALL_DIR} to #{path.join(@gamePath, "bootstrap.config")}."
        fs.writeFileSync path.join(@gamePath, "bootstrap.config"), JSON.stringify(bootstrap, null, 2)
        cb null

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
      @setupBootstrap (err) =>
        if err?
          cb err
        else
          if CONFIG.isServer
            @mods.init @modPath, @realAssetPath, cb
          else
            cb null
      process.on 'SIGINT', =>
        process.stdout.write "Starbind shutting down, reverting bootstrap.config changes..."
        @resetBootstrap()
        console.log "Done."
        process.exit(0)
      process.on 'exit', =>
        process.stdout.write "Starbind shutting down, reverting bootstrap.config changes..."
        @resetBootstrap()
        console.log "Done."
        process.exit(0)
    else
      cb null

