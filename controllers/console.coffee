auth = require '../lib/auth'
sms = require '../lib/sms'

module.exports = (app)->

  app.get '/console', auth.isAuthenticated(), (req, res)->
    res.render 'console'

  app.get '/sms/left', auth.isAuthenticated(),(req, res)->
    sms.left(res)