auth = require '../lib/auth'
passport = require 'passport'

module.exports = (app)->

  app.get '/', (req, res)->
    error =req.flash 'error'
    model = {}
    if error
      model.message = error[0]
    res.render 'index', model

  app.get '/setting', (req, res)->
    res.render 'setting'

  app.post '/login', (req, res)->
    data = req.body
    if data.action == 'apply'
      return res.direct '/apply'
    if !data.username || !data.password
      return res.render 'index', message:'用户名或密码不能为空'
    passport.authenticate('local',
      successRedirect:req.session.goingTo || '/console'
      failureRedirect:'/'
      failureFlash:true)(req, res)
