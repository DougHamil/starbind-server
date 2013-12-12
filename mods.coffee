fs = require 'fs'
unzip = require 'unzip'
path = require 'path'
AdmZip = require 'adm-zip'
readdirp = require 'readdirp'
mkdirp = require 'mkdirp'
_ = require 'underscore'
rimraf = require 'rimraf'

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

  init: (dir, cb)->
    @dir = dir
    @update(cb)

  # Update the mod package index
  update: (cb)->
    @index = {}
    fs.readdir @dir, (err, files) =>
      zipFiles = []
      files.forEach (file) =>
        if @validFile(file)
          zipFiles.push file
      handleNext = (cb) =>
        if zipFiles.length > 0
          file = zipFiles.pop()
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
            console.log "Error reading #{file}"
          handleNext(cb)
        else
          cb null
      handleNext(cb)

  validFile: (filename) ->
    return filename.match(/.zip$/)?

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
              zipFiles = []
              files.forEach (file) =>
                if @validFile(file)
                  zipFiles.push file
                else
                  console.log "Bad mod file: #{file}"
              extractNext = (cb) =>
                if zipFiles.length > 0
                  file = zipFiles.pop()
                  console.log "Installing mod #{file}..."
                  fs.createReadStream(path.join(@dir,file))
                    .pipe(unzip.Extract({path: destDir})).on('close', () -> extractNext(cb))
                else
                  cb null
              extractNext cb
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

  extractModConf: (zipEntries) ->
    for entry in zipEntries
      if modconfs[entry.entryName]
        try
          return modconfs[entry.entryName](JSON.parse(entry.getData().toString()))
        catch err
          console.warn "Unable to parse #{entry.entryName}"
    return null
