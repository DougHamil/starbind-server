CONFIG = require './server/config'
Git = require 'gift'
path = require 'path'
fs = require 'fs'
unzip = require 'unzip'

repoPath = path.join CONFIG.STARBOUND_INSTALL_DIR, 'mods'
gamePaths = []
gamePaths.push path.join CONFIG.STARBOUND_INSTALL_DIR, "linux64"
gamePaths.push path.join CONFIG.STARBOUND_INSTALL_DIR, "linux32"
gamePaths.push path.join CONFIG.STARBOUND_INSTALL_DIR, "win32"
gamePaths.push path.join CONFIG.STARBOUND_INSTALL_DIR, "Starbound.app/Contents/MacOS"

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
  serverProcess: null
  log:[]
  assetPath: repoPath
  installFound:false
  getAssetPath: (prop) ->
    return path.join @assetPath, prop
  getBranches: (cb) ->
    @repo.branches cb
  addModsDirToBootstrap: () ->
    for exeDir in gamePaths
      data = fs.readFileSync(path.join(exeDir, "bootstrap.config"), 'utf8')
      if data?
        bootstrap = JSON.parse(data)
        changed = false
        if "../assets" in bootstrap.assetSources
          if "../mods" not in bootstrap.assetSources
            bootstrap.assetSources.push "../mods"
            changed = true
        else if "../../../assets" in bootstrap.assetSources
          if "../../../mods" not in bootstrap.assetSources
            bootstrap.assetSources.push "../../../mods"
            changed = true
        if changed
          fs.writeFileSync path.join(exeDir, "bootstrap.config"), JSON.stringify(bootstrap, null, 2)
  mergeMods: (cb) ->
    modsDir = path.join(process.cwd(), "mods")
    assetPath = @assetPath
    fs.readdir modsDir, (err, files) =>
      if err?
        cb err
      else
        zipFiles = []
        files.forEach (file) ->
          if file.match(/.zip$/)?
            zipFiles.push file
          else
            console.log "Bad mod file: #{file}"
        commit = (cb) =>
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

        extractNext = (cb) =>
          if zipFiles.length > 0
            file = zipFiles.pop()
            console.log "Merging mod #{file}..."
            fs.createReadStream(path.join(modsDir,file)).pipe(unzip.Extract({path: assetPath})).on('close', () -> extractNext(cb))
          else
            commit cb
        extractNext cb

  init: (cb) ->
    @installFound = fs.existsSync(CONFIG.STARBOUND_INSTALL_DIR)

    if not fs.existsSync(path.join(process.cwd(), "mods"))
      fs.mkdir path.join(process.cwd(), "mods")
    if not fs.existsSync(@assetPath)
      fs.mkdir @assetPath
    @addModsDirToBootstrap()
    if not fs.existsSync(path.join(@assetPath, '.git'))
      console.log "Initializing git repo at #{@assetPath}"
      Git.init @assetPath, (err, repo) =>
        @repo = repo
        console.log "Detected first time repo creation."
        console.log "Creating default git ignore file..."
        copyFile path.join(__dirname, 'starboundgitignore'), path.join(@assetPath, '.gitignore'), (err) =>
          if not err?
            console.log "Done."
            console.log "Adding files to repo..."
            @repo.add ".", (err) =>
              console.log "Done"
              console.log "Creating initial commit..."
              @repo.commit 'INITIAL', (err) =>
                if not err? or err.toString() == 'Error: stdout maxBuffer exceeded.'
                  console.log "Done"
                  err = null
                cb err
          else
            cb err
    else
      @repo = Git @assetPath
      cb null
