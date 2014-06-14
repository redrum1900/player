Redis = require 'redis'
LOGIN_EXPIRE_TIME = 60*60
CODE_EXPIRE_TIME = 60
logger = require('log4js').getLogger('Redis')

client = {}

module.exports =
  config: (conf)->
    host = null
    port = null
    if !debug
      host = conf.host
      port = conf.port
    options = "no_ready_check":true
    client = Redis.createClient(port, host, options)
    client.on 'error', (err)->
      logger.error err
    if !debug
      client.auth conf.username+'-'+conf.password+'-'+conf.db
  setUser:(user,next)->
    client.setex user.id, LOGIN_EXPIRE_TIME, JSON.stringify(user),(err, result)->
      logger.error "Set User Error:"+err if err
      if result
        next result
      else
        next null
  getUser:(id,next)->
    client.get id, (err, result)->
      logger.error "Get Item Error:"+err if err
      if result
        if next
          next result
        client.expire id, LOGIN_EXPIRE_TIME
      else if next
        next null
  setCode:(mobile,code,next)->
    client.setex mobile, CODE_EXPIRE_TIME, code,(err, result)->
      logger.error "Set Code Error:"+err if err
      if result && next
        next result
      else if next
        next null
  getCode:(mobile,next)->
    client.get mobile, (err, result)->
      logger.error "Get mobile Error:", err if err
      if result && next
          next result
      else if next
        next null
  delItem:(key,next)->
    client.del key, (err, result)->
      logger.error "delItem Error:", err if err
      if result
        if next
          next result
      else if next
        next null