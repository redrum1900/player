Redis = require 'redis'
LOGIN_EXPIRE_TIME = 60*60
CODE_EXPIRE_TIME = 60

module.exports =
  config: (conf)->
    host = null
    port = null
    if debug
      host = conf.host
      port = conf.port
    options = "no_ready_check":true
    client = Redis.createClient(port, host, options)
    this.client = client
    client.on 'error', (err)->
      console.error err
    if debug
      client.auth conf.username+'-'+conf.password+'-'+conf.db
  setUser:(user,next)->
    client.setex user.id, LOGIN_EXPIRE_TIME, JSON.stringify(user),(err, result)->
      console.error "Set User Error", err if err
      if result
        next result
      else
        next null
  getUser:(id,next)->
    client.get id, (err, result)->
      console.error "Get Item Error:", err if err
      if result
        if next
          next result
        client.expire id, LOGIN_EXPIRE_TIME
      else if next
        next null
  setCode:(mobile,code,next)->
    client.setex mobile, CODE_EXPIRE_TIME, code,(err, result)->
      console.error "Set Code Error", err if err
      if result && next
        next result
      else if next
        next null
  getCode:(mobile,next)->
    client.get mobile, (err, result)->
      console.error "Get mobile Error:", err if err
      if result && next
          next result
      else if next
        next null
  delItem:(key,next)->
    client.del key, (err, result)->
      console.error "delItem Error:", err if err
      if result
        if next
          next result
      else if next
        next null