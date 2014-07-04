auth = require '../lib/auth'
sms = require '../lib/sms'

module.exports = (app)->

  app.get '/console', auth.isAuthenticated(), (req, res)->
    console.log('AKSK:'+process.env.BAE_ENV_AK, process.env.BAE_ENV_SK)
    res.render 'console'

  app.get '/sms/left', auth.isAuthenticated(),(req, res)->
    sms.left(res)