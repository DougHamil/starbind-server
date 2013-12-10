fs = require 'fs'
unzip = require 'unzip'
path = require 'path'
AdmZip = require 'adm-zip'

module.exports =
  packages: {}
  init: (dir, cb)->
    @dir = dir
    @update(cb)
  update: (cb)->
    @packages = {}
    fs.readdir @dir, (err, files) =>
      zipFiles = []
      files.forEach (file) =>
        if @validFile(file)
          zipFiles.push file
      handleNext = (cb) =>
        if zipFiles.length > 0
          file = zipFiles.pop()
          try
            console.log "Examining mod #{file}"
            zipFile = new AdmZip(path.join(@dir, file))
            zipEntries = zipFile.getEntries()
            confData = null
            zipEntries.forEach (entry) ->
              if entry.entryName is 'mod.conf'
                try
                  confData = JSON.parse(entry.getData().toString())
                catch err
                  confData = null
            if confData?
              console.log "Mod author is #{confData.author}"
            else
              console.log "mod.conf file not found for #{file}"
          catch err
            console.log "Error reading #{file}"
          handleNext(cb)
        else
          cb null
      handleNext(cb)

  validFile: (filename) ->
    return filename.match(/.zip$/)?

  extractTo: (destDir, cb) ->
    fs.readdir @dir, (err, files) =>
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
            fs.createReadStream(path.join(@dir,file)).pipe(unzip.Extract({path: destDir})).on('close', () -> extractNext(cb))
          else
            cb null

        extractNext cb


