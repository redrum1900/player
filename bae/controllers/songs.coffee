auth = require '../lib/auth'
Song = require('../models').Song
Dict = require('../models').Dict
UpdateObject = require('../lib/utils').updateObject

module.exports = (app)->

  updateTags = (tags)->
    if tags
      Dict.findOne
        'key':'SongTags'
        (err, dic) ->
          if dic.list
            tags.forEach (tag) ->
              dic.list.addToSet tag if dic.list.indexOf(tag) == -1
          else
            dic.list = result.tags
          dic.save()

  app.get '/songs', auth.isAuthenticated(), (req, res)->
    res.render 'songs'

  app.get '/song/list', auth.isAuthenticated(), (req, res) ->
    data = req.query
    query = {}
    query = 'name':new RegExp data.name, 'i' if data.name
    tags = data.tags
    if tags
      arr = tags.split ','
      query.tags = $all:arr
    Song.find(query).populate('creator', 'username')
    .populate('updator', 'username')
    .sort('created_at':-1)
    .limit(data.perPage)
    .skip(data.perPage*(data.page-1))
    .exec (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, results:result

  app.post '/song/update', auth.isAuthenticated(), (req, res) ->
    data = req.body
    data.updator = req.user._id
    Song.findById data._id, (err, result) ->
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

  app.post '/song/update/status', auth.isAuthenticated(), (req, res) ->
    data = req.body
    Song.findByIdAndUpdate data._id, $set:disabled:data.disabled, (err, result) ->
      if err
        Error err, res
      else
        res.json status:true, result:result

  app.post '/song/add', auth.isAuthenticated(), (req, res) ->
    data = req.body
    song = new Song data
    song.creator = req.user
    song.save (err, result) ->
      if err
        Error err, res
      else
        updateTags result.tags
        res.json status:true, results:result