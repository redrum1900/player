auth = require '../lib/auth'
models = require '../models'
Manager = models.Manager
Client = models.Client
Dict = models.Dict
SMS = models.SMS
Song = models.Song
Menu = models.Menu
UpdateObject = require('../lib/utils').updateObject
qiniu = require 'qiniu'
logger = require('log4js').getLogger('Menu')

module.exports = (app)->

  app.get '/api/menu/list', (req, res)->
    id = req.query.id
    query = {disabled:false}
    query.clients = id
    query.end_date = $gt:new Date()
    Menu.find(query)
    .select('_id')
    .exec (err, result)->
      if err
        Error err, res
      else
        res.json status:true, results:result

  saveMenu = (id, callback)->
    Menu.findById(id)
    .select('name list begin_date end_date')
    .populate('list.songs.song', 'name cover url duration')
    .exec (err, result)->
      extra = new qiniu.io.PutExtra()
      putPolicy = new qiniu.rs.PutPolicy('yfcdn')
      token = putPolicy.token()
      qiniu.io.put token, id+'.json', JSON.stringify(result), extra, (err, result)->
        if !err
          logger.trace result
          callback true
        else
          logger.error err
          callback false

  app.get '/menu', auth.isAuthenticated(), (req, res)->
    res.render 'menu'

  updateTags = (tags)->
    if tags
      Dict.findOne
        'key':'MenuTags'
        (err, dic) ->
          if dic
            if dic.list
              tags.forEach (tag) ->
                dic.list.addToSet tag if dic.list.indexOf(tag) == -1
            else
              dic.list = tags
          else
            dic = new Dict(key:'MenuTags',list:tags)
          dic.save()

  app.get '/menu/list', auth.isAuthenticated(), (req, res) ->
    data = req.query
    query = {}
    query = 'name':new RegExp data.name, 'i' if data.name
    tags = data.tags
    if tags
      arr = tags.split ','
      query.tags = $all:arr
    Menu.find(query)
    .populate('creator', 'username')
    .populate('updator', 'username')
    .populate('list.songs.song', 'name duration')
    .sort('created_at':-1)
    .limit(data.perPage)
    .skip(data.perPage*(data.page-1))
    .exec (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, results:result

  app.post '/menu/update', auth.isAuthenticated(), (req, res) ->
    data = req.body
    Menu.findById data._id, (err, result) ->
      if err
        Error err, res
      else
        UpdateObject result, data
        result.updator = req.user
        result.save (err, result) ->
          if err
            Error err, res
          else
            updateTags result.tags
            saveMenu result.id, (value)->
              if value
                res.json status:true, results:result
              else
                res.json status:false, results:'保存歌单失败'

  app.post '/menu/update/status', auth.isAuthenticated(), (req, res) ->
    data = req.body
    Menu.findByIdAndUpdate data._id, $set:disabled:data.disabled, (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, result:result

  app.post '/menu/add', auth.isAuthenticated(), (req, res) ->
    data = req.body
    menu = new Menu data
    menu.creator = req.user
    menu.save (err, result) ->
      console.log 'save menu', err, result
      if err
        Error err, res
      else
        updateTags result.tags
        saveMenu result.id, (value)->
          if value
            res.json status:true, results:result
          else
            res.json status:false, results:'保存歌单失败'