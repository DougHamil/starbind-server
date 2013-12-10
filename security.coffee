CONFIG = require './server/config'
fs = require 'fs'

credentials = null
if CONFIG.HTTPS_KEY_FILE? and CONFIG.HTTPS_CERT_FILE?
  keyFile = path.join(CONFIG.HTTPS_KEY_FILE)
  certFile = path.join(CONFIG.HTTPS_CERT_FILE)
  if fs.existsSync(keyFile)
    if fs.existsSync(certFile)
      privateKey = fs.readFileSync(keyFile, 'utf8')
      cert = fs.readFileSync(certFile, 'utf8')
      if cert? and privateKey?
        credentials = {key:privateKey, cert:cert}
    else
      console.warn "Unable to find HTTPS certificate at #{certFile}"
  else
    console.warn "Unable to find HTTPS key at #{keyFile}"

module.exports =
  httpsCredentials:credentials
  authHandler: (req, res, next) ->
    if CONFIG.isServer
      # All Git server requests are fine
      if req.path.indexOf('/starbound-server.git') == 0 or req.path.indexOf('/login') == 0 or req.path.indexOf('/logout') == 0
        next()
      else
        if req.session.loggedIn? and req.session.loggedIn
          next()
        else
          res.redirect '/login'
    else
      next()


