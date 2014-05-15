models = require('../models')
User = models.Client
auth = require '../lib/auth'
Error = require '../lib/error'
UpdateObject = require('../lib/utils').updateObject
Redis = require '../lib/database/redis'
SMS = require '../lib/sms'
EventProxy = require 'eventproxy'

module.exports = (app) ->

  app.get '/clients', auth.isAuthenticated(), (req, res) ->
    res.render 'clients'

  app.post '/api/user/login', (req, res)->
    data = req.body
    if !data.udid && (!data.mobile || !data.code)
      return res.json status:false, result:'udid或手机号&验证码不能为空'

    ep = new EventProxy()
    ep.once 'save', (user)->
      Redis.setUser user, (ret)->
        if ret
          reply null, user, res
        else
          reply '服务出错，请稍后再试', null, res

    if data.mobile
      User.getAuthenticated data.mobile, data.code, (err, result)->
        if err
          reply err, result, res
        else
          ep.emit 'save', result
    else
      User.findOne udid:data.udid, '-last_login_time -signed_in_times -updated_at -password -come_from -loginAttempts -lockUntil -creator -updator', (err, result)->
        if err
          reply err, result, res
        else if result
          result.signed_in_times++
          result.save()
          ep.emit 'save', result
        else
          user = new User data
          user.come_from = 'app'
          user.save (err, result)->
            ep.emit 'save', result


  app.post '/api/user/code', (req, res)->
    data = req.body
    if !data.mobile || !data.udid
      return res.json status:false, result:'手机号或设备号不能为空'
    Redis.getCode data.mobile, (result)->
      if result
        return res.json status:false, result:'需要60秒后才能再试'
      else
        ep = new EventProxy()
        code = Math.ceil(Math.random() * 899999)+100000;
        ep.once 'send', ->
          SMS.send data.mobile, '联想移动用户体验验证码：'+code, (result)->
          if result.status
            Redis.setCode data.mobile, code
            res.json status:true
          else
            res.json status:false
        User.findOne mobile:data.mobile, (err, result)->
          if err
            reply err, result, res
          else if result
            result.password = code
            result.save (err, result)->
              if err
                res.json status:false
              else
                ep.emit 'send'
          else
            User.findOne uidi:data.udid, (err, result)->
              if err
                reply err, result, res
              else if result
                unless result.mobile or result.mobile == data.mobile
                  result.password = code
                  result.mobile = data.mobile
                  result.save (err, result)->
                    if err
                      reply err, result, res
                    else
                      ep.emit 'send'
                else
                  user = new User data
                  user.come_from = 'app'
                  user.password = code
                  user.save (err, result)->
                    if err
                      reply err, result, res
                    else
                      ep.emit 'send'
              else
                res.json status:false, result:'用户设备尚未初始化'

  app.get '/user/list', auth.isAuthenticated(), (req, res) ->
    data = req.query
    query = {}
    query = 'username':new RegExp data.username, 'i' if data.username
    User.find(query).populate('creator', 'username')
    .populate('updator', 'username')
    .populate('parent', 'username')
    .sort('created_at':-1)
    .limit(data.perPage)
    .skip(data.perPage*(data.page-1))
    .exec (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, results:result

  app.post '/user/update', auth.isAuthenticated(), (req, res) ->
    data = req.body
    data.updator = req.user._id
    User.findById data._id, (err, result) ->
      if err
        Error err, res
      else
        UpdateObject result, data
        result.save (err, result) ->
          if err
            Error err, res
          else
            res.json status:true, results:result

  app.get '/user/parents', auth.isAuthenticated(), (req, res)->
    data = req.query
    User.find(parent:null).populate('parent', 'username').select('username parent').exec (err, result)->
      res.json result:result

  app.post '/user/update/status', auth.isAuthenticated(), (req, res) ->
    data = req.body
    User.findByIdAndUpdate data._id, $set:disabled:data.disabled, (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, result:result

  app.post '/user/add', auth.isAuthenticated(), (req, res) ->
    data = req.body
    if data.parent
      data.username = data.parent.username+':'+data.username
      data.parent = data.parent._id
    user = new User data
    user.creator = req.user
    code = Math.floor(Math.random()*899999) + 100000
    user.code = code
    user.password = code
    user.save (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, results:result