CONFIG = require './server/config'
mods = require './mods'
Git = require 'gift'
path = require 'path'
fs = require 'fs'
unzip = require 'unzip'
rimraf = require 'rimraf'
ncp = require 'ncp'
os = require 'os'
temp = require 'temp'
temp.track()

MOD_INSTALL_DIR = 'starbind_mods'

repoPath = path.join CONFIG.STARBOUND_INSTALL_DIR, MOD_INSTALL_DIR
gamePath = null
platform = os.platform()
arch = os.arch()
if platform is 'linux' and arch is 'x64'
  gamePath = 'linux64'
else if platform is 'linux'
  gamePath = 'linux32'
else if platform is 'win32'
  gamePath = 'win32'
else if platform is 'darwin'
  gamePath = 'Starbound.app/Contents/MacOS'
else
  console.log "Unable to determine OS platform, defaulting to linux64!"
  gamePath = 'linux64'

gamePath = path.join CONFIG.STARBOUND_INSTALL_DIR, gamePath

console.log "Starbound game path set to: #{gamePath}"

copyFile = (source, target, cb) ->
  cbCalled = false
  rd = fs.createReadStream(source)
  rd.on "error", (err) ->
    done(err)
  wr = fs.createWriteStream(target)
  wr.on "error", (err) ->
    done(err)
  wr.on "close", (ex) ->
    done()
  rd.pipe(wr)
  done = (err) ->
    if not cbCalled
      cb err
      cbCalled = true

module.exports =
  mods:mods
  serverProcess: null
  log:[]
  modPath: path.join(process.cwd(), 'mods')
  gamePath:gamePath
  assetPath: repoPath
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
  mergeMods: (cb) ->
    modsDir = path.join(process.cwd(), "mods")
    # Backup git file
    temp.mkdir 'starbind_git', (err, tempDir) =>
      ncp path.join(@assetPath, '.git'), tempDir, (err) =>
        # Purge the asset path
        rimraf @assetPath, =>
          fs.mkdirSync @assetPath
          @mods.extractTo @assetPath, (err) =>
            if err?
              cb err
            else
              # Copy git repo back
              ncp tempDir, path.join(@assetPath, '.git'), (err) =>
                temp.cleanup()
                @repo.status (err, status) =>
                  if err?
                    cb err
                  else
                    # Do nothing if there were no changes
                    if status.clean
                      console.log "No changes made since last merge."
                      cb null
                    else
                      console.log "Done merging mods, committing changes to repo"
                      @repo.add '.', (err) =>
                        @repo.commit 'Mod Merge', (err) =>
                          if not err? or err.toString() == 'Error: stdout maxBuffer exceeded.'
                            console.log "Done"
                            err = null
                          cb err

  init: (cb) ->
    @installFound = fs.existsSync(CONFIG.STARBOUND_INSTALL_DIR)
    if not fs.existsSync(@modPath)
      console.log "Creating mod package directory at #{@modPath}"
      fs.mkdirSync @modPath
    if not fs.existsSync(@assetPath)
      console.log "Creating assets directory for mod installation at #{@assetPath}"
      fs.mkdirSync @assetPath
    if @installFound
      @addModsDirToBootstrap()
    initGit = (cb) =>
      if not fs.existsSync(path.join(@assetPath, '.git'))
        console.log "Initializing git repo at #{@assetPath}"
        Git.init @assetPath, (err, repo) =>
          @repo = repo
          cb err
      else
        @repo = Git @assetPath
        cb null
    if CONFIG.isServer
      @mods.init @modPath, (err) =>
        initGit cb
    else
      initGit cb

