qiniu = require 'qiniu'
auth = require '../lib/auth'

module.exports = (app)->
  qiniu.conf.ACCESS_KEY = 'xyGeW-ThOyxd7OIkwVKoD4tHZmX0K0cYJ6g1kq4J';
  qiniu.conf.SECRET_KEY = 'bJSwo1--7pa-HD3g7fFHaI6e_TOYP1NCk3Z7XM7G';

  app.get '/upload/token', auth.isAuthenticated(), (req, res)->
    putPolicy = new qiniu.rs.PutPolicy('yfcdn')
    putPolicy.expires = 3600
    res.json uptoken:putPolicy.token()

  app.get '/upload/token/mp3', auth.isAuthenticated(), (req, res)->
    putPolicy = new qiniu.rs.PutPolicy('yfcdn')
    putPolicy.expires = 3600
    putPolicy.persistentOps = 'avthumb/mp3/ab/192k;avthumb/mp3/ab/64k'
    res.json uptoken:putPolicy.token()