CONFIG = require './server/config'
Git = require 'gift'
path = require 'path'
fs = require 'fs'

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
  init: (cb) ->
    console.log "Initializing git repo at #{@assetPath}"
    Git.init @assetPath, (err, repo) =>
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
