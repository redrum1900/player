Manager = require('../models').Manager
LocalStrategy = require('passport-local').Strategy
log4js = require('log4js')
logger = log4js.getLogger('Auth')

exports.config = (settings)->
  return

exports.localStrategy = ->
  return new LocalStrategy (username, password, done) ->
    Manager.getAuthenticated username, password, (err, user, reason)->
      if(err)
        logger.error(err)
      else if(reason != null)
        logger.warn('Login Failed:'+username+'-'+password+'-'+reason);
      if(!user)
        return done(err, false, {message:reason});
      done(null, user)

exports.isAuthenticated =  (role) ->
  return  (req, res, next)->
    if (!req.isAuthenticated())
      req.session.goingTo = req.url
      res.redirect('/')
    else
      if (role && req.user.role != role)
        res.status(401)
        res.render('errors/401')
      next();

exports.injectUser = (req, res, next)->
  if req.isAuthenticated()
    user = req.user
    res.locals.user = user
    res.locals.path = req.path
    navs = [
      {href:'/console', label:'控制台'},
      {href:'/songs', label:'媒资管理'},
      {href:'/menu', label:'歌单推送'},
      {href:'/clients', label:'客户管理'},
      {href:'/feedback', label:'客户反馈'},
      {href:'/log', label:'操作日志'}
    ]
    if user.role == 0
      navs.push {href:'/setting', label:'系统设置'}
    res.locals.navs = JSON.stringify navs
  next()