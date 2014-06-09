models = require '../models'
Log = models.Log
auth = require '../lib/auth'

module.exports = (app)->

  app.get '/logs', auth.isAuthenticated(), (req, res)->
