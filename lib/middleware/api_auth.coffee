Redis = require '../database/redis'

module.exports = ->
  routes = [
    '/api/menu/get'
  ]
  return (req, res, next)->
    path = req._parsedUrl.pathname
    id = if req.method == 'GET' then req.query.id else req.body.id
    if routes.indexOf(path) != -1
      if id
        Redis.getUser id, (err, result)->
          if result
            next()
          else if err
            res.json({status: false, result: '出错啦，请稍后再试', need_login:true})
          else
            res.json({status: false, result: '请登录后再试', need_login:true})
      else
        res.json({status:false, result:'请登录后再试', need_login:true})
    else
      if id
        Redis.getUser id
      next()