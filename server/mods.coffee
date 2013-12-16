fs = require 'fs'
unzip = require 'unzip'
path = require 'path'
AdmZip = require 'adm-zip'
readdirp = require 'readdirp'
mkdirp = require 'mkdirp'
_ = require 'underscore'
rimraf = require 'rimraf'
async = require 'async'
require 'colors'
S = require 'string'
deepmerge = require 'deepmerge'
JSONStream = require 'JSONStream'
es = require 'event-stream'
minify = require('./minify').minify

UNMERGEABLE_FILE_EXTS = ['.ogg', '.png', '.tif', '.wav', '.abc']

# Handlers for various types of mod meta-data
modconfs =
  ".*[/\]?mod\.json": (data) ->
    conf =
      id: data["internal-name"]
      name: data.name
      version: data.version
      description: data.description
      author:data.author
      url: data.url
  ".*\.modinfo": (data) ->
    conf =
      id: data.name
      version: data.version
      description: data.description # not supported in modinfo
      author: data.author # no supported in modinfo
      path: data.path
      dependencies: data.dependencies

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
            console.log "Found metadata for #{file}".green
          else
            confData =
              file: file
            console.log "No metadata file found for #{file}".yellow
          # update index
          @index[confData.file] = confData
        catch err
          console.log "Error extracting mods #{err}"
          cb err
        cb null
      async.each zipFiles, handleZipFile, cb

  updateGameIndex: (cb) ->
    @gameRootFolders = {}
    @gameIndex = {}
    process.stdout.write "Indexing Starbound assets directory for mod merging..."
    searchStream = readdirp {root:@realDir, fileFilter:UNMERGEABLE_FILE_EXTS.map (ext) -> '!'+ext}
    searchStream.on 'error', (err) ->
      cb err
    searchStream.on 'data', (entry) =>
      if entry.path.indexOf('.git') == -1
        @gameRootFolders[path.dirname(entry.path)] = true
        @gameIndex[entry.path] = true
    searchStream.on 'end', =>
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

  # Does this zip file contain a root folder for the mod?
  hasOuterFolder: (modsDir, filename, cb) ->
    hasOuter = true
    fs.createReadStream(path.join(modsDir, filename)).pipe(unzip.Parse())
      .on 'entry', (entry) =>
        # If a directory is one of the root folders, then no outer folder
        if entry.type == 'Directory'
          if @gameRootFolders[entry.path]? and entry.path.toLowerCase() != 'assets'
            hasOuter = false
        else
          # If a file's path is equal to the file name, then no outer folder
          if path.basename(entry.path) is entry.path and entry.path.toLowerCase().indexOf('readme') == -1 # TODO: Remove this hack for readme files at the root
            hasOuter = false
        entry.autodrain()
      .on 'error', (err) ->
        cb err
      .on 'close', ->
        cb null, hasOuter

  extractEntry:(runningIndex, hasOuter, destDir, entry, cb) ->
    entryPath = entry.path
    if hasOuter
      entryPath = entryPath.split(path.sep)[1..]
      # Skip this entry if it was at root (probably a readme file)
      if entryPath.length == 0
        cb null
        return
      entryPath = path.join entryPath...
    absEntryPath = path.join(destDir, entryPath)
    mkdirp.sync path.dirname(absEntryPath)
    if S(entryPath).right(4) in UNMERGEABLE_FILE_EXTS
      # Just write out the files, overwriting whatever was there previously
      console.log "Saving #{entryPath}"
      entry.pipe(fs.createWriteStream(absEntryPath))
        .on('finish', cb)
    else
      if runningIndex[entryPath]?
        console.log "Merging #{entryPath}"
        @mergeFiles absEntryPath, entry, (err, merged) =>
          fs.writeFile absEntryPath, JSON.stringify(merged, null, 2), cb
      else if @gameIndex[entryPath]?
        console.log "Merging #{entryPath}"
        @mergeFiles path.join(@realDir, entryPath), entry, (err, merged) =>
          fs.writeFile absEntryPath, JSON.stringify(merged, null, 2), cb
      else
        console.log "Saving #{entryPath}"
        outStream = fs.createWriteStream(absEntryPath)
        entry.pipe(outStream)
          .on 'error', (err) ->
            cb err
          .on 'finish', ->
            cb null
    runningIndex[entryPath] = true

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
                console.log "Installing mod #{file}..."
                @hasOuterFolder @dir, file, (err, hasOuter) =>
                  if err?
                    cb err
                  else
                    if hasOuter
                      console.log "#{file} has a nested folder".yellow
                    handleEntry = (entry) =>
                      if entry.type == 'File'
                        @extractEntry runningIndex, hasOuter, destDir, entry, (err) ->
                          if err?
                            console.log "Error extracting #{entry.path}:"
                            console.log err
                      else
                        # Skip directories
                        entry.autodrain()
                    fs.createReadStream(path.join(@dir,file))
                      .pipe(unzip.Parse())
                      .on('entry', handleEntry)
                      .on 'error', (err) ->
                        console.log "Error extracting #{file}: ".red
                        console.log err
                        cb err
                      .on 'close', ->
                        console.log "Successfully installed #{file}".green
                        cb null
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
        # We cannot use JSONStream here because it doesn't handle comments in json files
        zipString = ''
        zipEntry.on 'data', (data) ->
          zipString += data.toString()
        zipEntry.on 'error', cb
        zipEntry.on 'end', ->
          zipData = JSON.parse(minify(zipString))
          cb null, deepmerge(diskData, zipData)

  extractModConf: (zipEntries) ->
    for entry in zipEntries
      for reg, infoExtractor of modconfs
        if (new RegExp(reg, 'g')).test(entry.entryName.toLowerCase())
          try
            return infoExtractor(JSON.parse(minify(entry.getData().toString())))
          catch err
            console.warn "Unable to parse #{entry.entryName}"
            console.log err
    return null
