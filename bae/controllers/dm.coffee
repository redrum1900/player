auth = require '../lib/auth'
DM = require('../models').DM
Dict = require('../models').Dict
UpdateObject = require('../lib/utils').updateObject

module.exports = (app)->

  updateTags = (tags)->
    if tags
      Dict.findOne
        'key':'DMTags'
        (err, dic) ->
          if dic
            if dic.list
              tags.forEach (tag) ->
                dic.list.addToSet tag if dic.list.indexOf(tag) == -1
            else
              dic.list = tags
          else
            dic = new Dict(key:'DMTags',list:tags)
          dic.save()

  app.get '/dm', auth.isAuthenticated(), (req, res)->
    res.render 'dm'

  app.get '/dm_menu', auth.isAuthenticated(), (req, res)->
    res.render 'dm_menu'

  app.get '/dm/list', auth.isAuthenticated(), (req, res) ->
    data = req.query
    query = {}
    query = 'name':new RegExp data.name, 'i' if data.name
    tags = data.tags
    if tags
      arr = tags.split ','
      query.tags = $all:arr
    DM.find(query).populate('creator', 'username')
    .populate('updator', 'username')
    .sort('created_at':-1)
    .limit(data.perPage)
    .skip(data.perPage*(data.page-1))
    .exec (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, results:result

  app.post '/dm/update', auth.isAuthenticated(), (req, res) ->
    data = req.body
    data.updator = req.user._id
    DM.findById data._id, (err, result) ->
      if err
        Error err, res
      else
        UpdateObject result, data
        result.save (err, result) ->
          if err
            Error err, res
          else
            updateTags result.tags
            res.json status:true, results:result

  app.post '/dm/update/status', auth.isAuthenticated(), (req, res) ->
    data = req.body
    DM.findByIdAndUpdate data._id, $set:disabled:data.disabled, (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, result:result

  app.post '/dm/add', auth.isAuthenticated(), (req, res) ->
    data = req.body
    if data.published_at && data.published_at.indexOf('-') != 0
      arr = data.published_at.split('-')
      date = new Date(arr[0], arr[1], arr[2])
      data.published_at = date
    dm = new DM data
    dm.creator = req.user
    dm.save (err, result) ->
      if err
        Error err, res
      else
        updateTags result.tags
        res.json status:true, results:result