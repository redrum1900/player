auth = require '../lib/auth'
Song = require('../models').Song

module.exports = (app)->

  app.get '/songs', auth.isAuthenticated(), (req, res)->
    res.render 'songs'

  app.get '/song/list', auth.isAuthenticated(), (req, res) ->
    data = req.query
    query = {}
    query = 'name':new RegExp data.name, 'i' if data.name
    if data.tags
      arr = tags.split ','
      andArr = []
      arr.forEach (tag)->
        andArr.push tags:tag
      query.$and = andArr
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
            res.json status:true, results:result