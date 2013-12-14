os = require 'os'
fs = require 'fs'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
ncp = require 'ncp'
http = require 'http'
path = require 'path'

WINDOWS_NODEJS_EXE = 'http://nodejs.org/dist/v0.10.23/node.exe'

# Files to not copy to output directory
IGNORE_FILES = ['config_server.default.json', 'config.default.json', 'config.json', 'build.js', 'install.sh', 'run.sh', 'README.md', 'package.json']
# Directories not to copy to output directory
IGNORE_DIRS = ['build', 'mods']


module.exports = (cb)->
  if process.argv.length < 4
    cb "Expected platform and output directory"
    return

  platform = process.argv[2]

# Clean output directory
  outputDirectory = path.join(process.cwd(), process.argv[3])
  console.log "Output directory set to #{outputDirectory}"
  process.stdout.write 'Preparing output directory...'
  if fs.existsSync outputDirectory
    rimraf.sync outputDirectory
  mkdirp.sync outputDirectory
  console.log "Done."

  ignoreFiles = IGNORE_FILES.map (file) -> return path.join(process.cwd(), file)
  ignoreDirs = IGNORE_DIRS.map (dir) -> return path.join(process.cwd(), dir)

  opts =
    filter: (file) ->
      if file in ignoreFiles
        return false
      else
        for dir in ignoreDirs
          if file.indexOf(dir) == 0
            return false
        return true

  # Called after scripts are copied
  postCopy = (cb) ->
    switch platform
      when "win32"
        process.stdout.write "Downloading node.exe..."
        http.get WINDOWS_NODEJS_EXE, (res) ->
          res.pipe(fs.createWriteStream(path.join(outputDirectory, 'node.exe'), {flags:'w', encoding:null, mode:777}))
            .on 'close', ->
              console.log "Done."
              cb(null)
            .on('error', cb)
  #
  # Copy files
  process.stdout.write "Copying scripts..."
  ncp process.cwd(), outputDirectory, opts, (err) ->
    if err?
      cb err
    else
      fs.mkdirSync path.join(outputDirectory, 'mods')
      fs.createReadStream(path.join(process.cwd(), 'config.default.json')).pipe(fs.createWriteStream(path.join(outputDirectory, 'config.json')))
        .on 'close', ->
          console.log "Done."
          postCopy(cb)
        .on('error', cb)





