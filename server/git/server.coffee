CONFIG = require '../config'
path = require 'path'
http = require 'http'
handle = require './handle'
EventEmitter = require('events').EventEmitter

ALLOW_ANON_READS = true

if CONFIG.ALLOW_ANON_PULL?
  ALLOW_ANON_READS = CONFIG.ALLOW_ANON_PULL

module.exports = (name, repoDir, users) ->
  dirMap = {}
  dirMap[name] = repoDir
  handler = new EventEmitter
  handler.autoCreate = false
  handler.exists = (repo, cb) ->
    cb repo is name
  handler.dirMap = (dir) ->
    if dir is name
      return repoDir
    else
      return path.join repoDir, dir
  handler.handle = handle

  # The following is extracted from NodeJS-Git-Server
  permMap = fetch: 'R', push: 'W'

  logging = true
  log = () ->
    args = for key, value of arguments
      "#{value}"
    if true then console.log "LOG: ", args.join(' ')

  getUser = (username, password) ->
    for userObject in users
      return userObject if userObject.user.username is username and userObject.user.password is password
    false

  permissableMethod = (username, password, method, gitObject) ->
    log(username, 'is trying to', method, '...')
    user = getUser(username, password)
    if user is false
      log(username, 'was rejected as this user doesnt exist, or password is wrong')
      gitObject.reject(500, 'Wrong username or password')
    else
      if permMap[method] in user.permissions
        log(username, 'Successfully did a', method)
        gitObject.accept()
      else
        log(username, 'was rejected, no permission to', method)
        gitObject.reject 500, "You don't have these permissions"

  processSecurity = (gitObject, method) ->
    req = gitObject.request
    res = gitObject.response
    auth = req.headers['authorization']
    if auth is undefined
      res.statusCode = 401;
      res.setHeader('WWW-Authenticate', 'Basic realm="Secure Area"')
      res.end('<html><body>Need some creds son</body></html>')
    else
      plain_auth = (new Buffer(auth.split(' ')[1], 'base64')).toString()
      creds = plain_auth.split(':')
      permissableMethod(creds[0], creds[1], method, gitObject)

  onPush = (push) ->
    log 'Got a PUSH call for', push.repo
    if push.repo is name
      processSecurity push, 'push'
    else
      push.reject 500, 'This repo doesn\'t exist'

  onFetch = (fetch) ->
    log 'Got a FETCH call for', fetch.repo
    if fetch.repo is name
      if ALLOW_ANON_READS
        fetch.accept()
      else
        processSecurity fetch, 'fetch'
    else
      fetch.reject 500, 'This repo doesn\'t exist'

  handler.on 'push', onPush
  handler.on 'fetch', onFetch
  handler.on 'info', onFetch

  return handler.handle.bind(handler)
