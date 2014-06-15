qiniu = require 'qiniu'
auth = require '../lib/auth'
logger = require('log4js').getDefaultLogger()
ErrorLog = require('../models').ErrorLog
Error = require('../lib/error')

module.exports = (app)->
  qiniu.conf.ACCESS_KEY = 'xyGeW-ThOyxd7OIkwVKoD4tHZmX0K0cYJ6g1kq4J';
  qiniu.conf.SECRET_KEY = 'bJSwo1--7pa-HD3g7fFHaI6e_TOYP1NCk3Z7XM7G';

  app.get '/upload/token', auth.isAuthenticated(), (req, res)->
    putPolicy = new qiniu.rs.PutPolicy('yfcdn')
    putPolicy.expires = 3600
    res.json uptoken:putPolicy.token()

  app.get '/log/token', (req, res)->
    putPolicy = new qiniu.rs.PutPolicy('yflog')
    putPolicy.expires = 3600
    putPolicy.callbackUrl = 'http://m.yuefu.com/logged'
    putPolicy.callbackBody = 'name=${key}&uploader='+req.query.id
    res.json uptoken:putPolicy.token()

  app.get '/upload/token/mp3', auth.isAuthenticated(), (req, res)->
    putPolicy = new qiniu.rs.PutPolicy('yfcdn')
    putPolicy.expires = 3600
    putPolicy.persistentOps = 'avthumb/mp3/ab/192k;avthumb/mp3/ab/64k'
    putPolicy.persistentNotifyUrl = 'http://m.yuefu.com/notify'
    res.json uptoken:putPolicy.token()

  app.get '/upload/token/mp3/auto', auth.isAuthenticated(), (req, res)->
    putPolicy = new qiniu.rs.PutPolicy('yfcdn')
    putPolicy.expires = 3600
    putPolicy.persistentOps = 'avthumb/mp3/ab/192k;avthumb/mp3/ab/64k'
    putPolicy.persistentNotifyUrl = 'http://m.yuefu.com/notify'
    putPolicy.callbackUrl = 'http://m.yuefu.com/callback'
    putPolicy.callbackBody = 'size=$(fsize)&info=$(avinfo)'
    res.json uptoken:putPolicy.token()

  app.post '/notify', (req, res)->
    logger.trace 'notify:'+JSON.stringify(req.body)
    res.json status:true, data:req.body

  app.post '/callback', (req, res)->
    logger.trace JSON.stringify(req.body)
    res.json status:true, data:req.body

  app.post '/logged', (req, res)->
    data = req.body
    uploader = data.uploader
    log = new ErrorLog(url:data.name,client:uploader)
    log.save (err, result)->
      if err
        Error err, res
      else
        logger.warn 'logged:'+uploader
        res.json status:true