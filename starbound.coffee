CONFIG = require './server/config'
Git = require 'gift'
path = require 'path'
fs = require 'fs'
unzip = require 'unzip'

repoPath = path.join CONFIG.STARBOUND_INSTALL_DIR, 'assets'

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
  getAssetPath: (prop) ->
    return path.join @assetPath, prop
  getBranches: (cb) ->
    @repo.branches cb
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
    console.log "Initializing git repo at #{@assetPath}"
    if not fs.existsSync(path.join(process.cwd(), "mods"))
      fs.mkdir path.join(process.cwd(), "mods")
    Git.init @assetPath, (err, repo) =>
      if err? or not repo?
        console.log "Repo not found: #{err}"
        @repo = null
        cb null
      else
        @repo = repo
        @repo.tree().contents (err, children) =>
          if err? and err.code == 128
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
            cb err
