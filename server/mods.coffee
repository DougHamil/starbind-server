fs = require 'fs'
unzip = require 'unzip'
path = require 'path'
AdmZip = require 'adm-zip'
readdirp = require 'readdirp'
mkdirp = require 'mkdirp'
_ = require 'underscore'
rimraf = require 'rimraf'
async = require 'async'
S = require 'string'
deepmerge = require 'deepmerge'
JSONStream = require 'JSONStream'
es = require 'event-stream'
minify = require('./minify').minify

UNMERGEABLE_FILE_EXTS = ['.ogg', '.png', '.tif', '.wav', '.abc']

# Handlers for various types of mod meta-data
modconfs =
  "mod.json": (data) ->
    conf =
      id: data["internal-name"]
      name: data.name
      version: data.version
      description: data.description
      author:data.author
      url: data.url

module.exports =
  index: {}
  gameIndex: {} # Index of all files currently in teh game

  init: (dir, realDir, cb)->
    @dir = dir
    @realDir = realDir
    @update (err) =>
      @updateGameIndex(cb)

  # Update the mod package index
  update: (cb)->
    @index = {}
    fs.readdir @dir, (err, files) =>
      zipFiles = files.filter (file) => @validFile(file)
      handleZipFile = (file, cb) =>
        try
          zipFile = new AdmZip(path.join(@dir, file))
          zipEntries = zipFile.getEntries()
          confData = @extractModConf zipEntries
          if confData?
            confData.file = file
          else
            confData =
              file: file
          # update index
          @index[confData.file] = confData
        catch err
          console.log "Error extracting mods #{err}"
          cb err
        cb null
      async.each zipFiles, handleZipFile, cb

  updateGameIndex: (cb) ->
    if false
      cb null
    else
      process.stdout.write "Indexing Starbound assets directory for mod merging..."
      searchStream = readdirp {root:@realDir, fileFilter:UNMERGEABLE_FILE_EXTS.map (ext) -> '!'+ext}
      searchStream.on 'error', (err) ->
        cb err
      searchStream.on 'data', (entry) =>
        if not S(entry.path).endsWith('.png')
          @gameIndex[entry.path] = true
      searchStream.on 'end', ->
        console.log "Done!"
        cb null

  validFile: (filename) ->
    return filename.match(/.zip$/)?

  loadAsset: (assetFile, cb) ->
    fs.readFile assetFile, 'utf8', (err, data) ->
      try
        cb err, JSON.parse(minify(data))
      catch err
        cb err, null

  # Extract all mod packages into destDir directory
  extractTo: (destDir, cb) ->
    extractPackages = =>
      fs.readdir @dir, (err, files) =>
        if err?
          cb err
        else
          # Make sure the dest directory is there
          mkdirp destDir, (err) =>
            if err?
              cb err
            else
              # Keep track of the files that have already been extracted to help with merging
              runningIndex = {}
              zipFiles = files.filter (file) => @validFile(file)
              extractAndMergeMod = (file, cb) =>
                process.stdout.write "Installing mod #{file}..."
                entriesToProcess = []
                storeEntry = (entry) =>
                  if entry.type == 'File'
                    entriesToProcess.push entry
                  else
                    entry.autodrain()
                handleEntry = (entry, cb) =>
                  mkdirp path.dirname(path.join(destDir,entry.path)), (err) =>
                    if not err?
                      if S(entry.path).right(4) in UNMERGEABLE_FILE_EXTS
                        # Just write out the files, overwriting whatever was there previously
                        entry.pipe(fs.createWriteStream(path.join(destDir, entry.path)))
                          .on('close', cb)
                      else
                        if runningIndex[entry.path]?
                          @mergeFiles path.join(destDir, entry.path), entry, (err, merged) =>
                            fs.writeFile path.join(destDir, entry.path), JSON.stringify(merged, null, 2), cb
                        else if @gameIndex[entry.path]?
                          @mergeFiles path.join(@realDir, entry.path), entry, (err, merged) =>
                            fs.writeFile path.join(destDir, entry.path), JSON.stringify(merged, null, 2), cb
                        else
                          entry.pipe(fs.createWriteStream(path.join(destDir, entry.path)))
                            .on('close', cb)
                      runningIndex[entry.path] = true
                    else
                      entry.autodrain()
                      cb err
                fs.createReadStream(path.join(@dir,file))
                  .pipe(unzip.Parse())
                  .on('entry', storeEntry)
                  .on('error', cb)
                  .on 'close', ->
                    async.each entriesToProcess, handleEntry, (err) ->
                      if err?
                        console.log "ERROR"
                      else
                        console.log "Done!"
                      cb err
              async.eachSeries zipFiles, extractAndMergeMod, (err) ->
                console.log "Done merging mods."
                cb err

    fs.exists destDir, (exists) =>
      if exists
        # Nuke the directory
        rimraf destDir, (err) =>
          if err?
            cb err
          else
            extractPackages()
      else
        extractPackages()

  mergeFiles: (diskFilePath, zipEntry, cb) ->
    @loadAsset diskFilePath, (err, diskData) ->
      if err?
        cb err
      else
        zipEntry.pipe(JSONStream.parse())
          .on 'error', (err) ->
            cb err
          .on 'root', (zipData) ->
            cb null, deepmerge(diskData, zipData)

  extractModConf: (zipEntries) ->
    for entry in zipEntries
      if modconfs[entry.entryName.toLowerCase()]
        try
          return modconfs[entry.entryName.toLowerCase()](JSON.parse(entry.getData().toString()))
        catch err
          console.warn "Unable to parse #{entry.entryName}"
    return null
