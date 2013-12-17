os = require 'os'
fs = require 'fs'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
ncp = require 'ncp'
http = require 'http'
path = require 'path'
tar = require 'tar'
S = require 'string'

WINDOWS_NODEJS_EXE = 'http://nodejs.org/dist/v0.10.23/node.exe'
MAC_NODEJS_EXE = 'http://nodejs.org/dist/v0.10.23/node-v0.10.23-darwin-x86.tar.gz'

# Files to not copy to output directory
IGNORE_FILES = ['config_server.default.json', 'config.default.json', 'config.json', 'build.js', 'install.sh', 'run.sh', '.nodemonignore', '.gitignore', 'README.md', 'package.json']
# Directories not to copy to output directory
IGNORE_DIRS = ['.git', 'build', 'mods']


module.exports = (cb)->
  if process.argv.length < 4
    cb "Expected platform and output directory"
    return

  platform = process.argv[2]

# Clean output directory
  outputDirectory = path.resolve(process.cwd(), process.argv[3])
  console.log "Output directory set to #{outputDirectory}"
  process.stdout.write 'Preparing output directory...'
  if fs.existsSync outputDirectory
    rimraf.sync outputDirectory
  mkdirp.sync outputDirectory
  console.log "Done."

  ignoreFiles = IGNORE_FILES.map (file) -> return path.resolve(process.cwd(), file).replace(/\\/g, '/')
  ignoreDirs = IGNORE_DIRS.map (dir) -> return path.resolve(process.cwd(), dir).replace(/\\/g, '/')

  opts =
    filter: (file) ->
      file = file.replace(/\\/g, '/')
      if file.indexOf('.git/') != -1
        return false
      else if file in ignoreFiles
        return false
      else
        for dir in ignoreDirs
          if file.indexOf(dir) == 0
            return false
        return true
  archiveOutputDirectory = (cb) ->
    cb null

  # Called after scripts are copied
  postCopy = (cb) ->
    switch platform
      when "win32"
        process.stdout.write "Downloading node.exe..."
        http.get WINDOWS_NODEJS_EXE, (res) ->
          res.pipe(fs.createWriteStream(path.join(outputDirectory, 'node.exe'), {flags:'w', encoding:null, mode:777}))
            .on 'close', ->
              console.log "Done."
              archiveOutputDirectory(cb)
            .on('error', cb)
      when "darwin"
        step = 0
        nextStep = ->
          step++
          if step > 1
            archiveOutputDirectory(cb)

        process.stdout.write "Downloading node binaries..."
        http.get MAC_NODEJS_EXE, (res) ->
          tarFile = path.join(outputDirectory, 'node.tar.gz')
          res.pipe(fs.createWriteStream(tarFile), {flags:'w', encoding:null, mode:777})
            .on 'close', ->
              # Untar the binaries
              fs.createReadStream(tarFile).pipe(require('zlib').createGunzip()).pipe(tar.Parse())
                .on 'entry', (entry) ->
                  if S(entry.props.path).endsWith('node')
                    entry.pipe(fs.createWriteStream(path.join(outputDirectory, 'node')))
                      .on 'close', ->
                        fs.chmodSync path.join(outputDirectory, 'node'), '755'
                        console.log "Done."
                        nextStep()
                      .on('error', cb)
                .on('error', cb)
                .on 'end', ->
                  fs.unlinkSync tarFile
                  nextStep()
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

