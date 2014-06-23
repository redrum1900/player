models = require('../models')
User = models.Client
Menu = models.Menu
auth = require '../lib/auth'
Error = require '../lib/error'
UpdateObject = require('../lib/utils').updateObject
Redis = require '../lib/database/redis'
SMS = require '../lib/sms'
EventProxy = require 'eventproxy'
updateTags = models.updateTags
logger = require('log4js').getDefaultLogger()
Log = models.Log
moment = require 'moment'
mongoose = require 'mongoose'

module.exports = (app) ->

  app.get '/clients', auth.isAuthenticated(), (req, res) ->
    res.render 'clients'

  app.post '/api/user/login', (req, res)->
    data = req.body
    if !data.username || !data.password
      return res.json status:false, results:'用户名或密码不能为空'
    User.getAuthenticated data.username, data.password, (err, result)->
      mongoose.disconnect()
      if err
        Error err, res
      else
        res.json status:true, results:id:result.id,broadcasts:result.broadcasts

  app.get '/api/refresh', (req, res)->
    data = req.query
    if !data.id
      logger.warn 'no id to refresh', req.ip
      return res.json status:false

    ep = new EventProxy()
    ep.all 'log','bro','menu',(log, bro, menu)->
      mongoose.disconnect()
      res.json status:true,results:bros:bro.broadcasts,menus:menu

    ep.fail (err)->
      Error err, res

    Log.findOneAndUpdate
      client:data.id
      created_at:moment().format("YYYY-MM-DD")
    ,
      $inc:count:1
    ,
      upsert:true
    , ep.done('log')

    User.findById(data.id).select('broadcasts').exec ep.done('bro')

    Menu.find(disabled:false,clients:data.id,end_date:$gt:new Date()).select('_id updated_at end_date quality type').sort(end_date:1).exec ep.done('menu')


  app.get '/user/list', auth.isAuthenticated(), (req, res) ->
    data = req.query
    query = {}
    query = 'username':new RegExp data.username, 'i' if data.username
    tags = data.tags
    if tags
      arr = tags.split ','
      query.tags = $all:arr
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
            updateTags 'ClientTags', result.tags
            res.json status:true, results:result

  app.get '/user/parents', auth.isAuthenticated(), (req, res)->
    data = req.query
    User.find(parent:null).populate('parent', 'username').select('username parent').exec (err, result)->
      res.json result:result

  app.post '/user/update/status', auth.isAuthenticated(0), (req, res) ->
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
    if data.username.indexOf('@') != -1
      return res.json status:false, results:'用户名不能有邮件@符号'
    user = new User data
    user.creator = req.user
    code = Math.floor(Math.random()*899999) + 100000
    user.code = code
    user.password = code
    user.save (err, result) ->
      if err
        Error err, res
      else
        updateTags 'ClientTags', result.tags
        res.json status:true, results:result