auth = require '../lib/auth'
models = require '../models'
Manager = models.Manager
Client = models.Client
Dict = models.Dict
SMS = models.SMS
Song = models.Song
Menu = models.Menu
moment = require 'moment'
UpdateObject = require('../lib/utils').updateObject
qiniu = require 'qiniu'
logger = require('log4js').getLogger('Menu')
xlsx = require 'node-xlsx'
EventProxy = require 'eventproxy'
mongoose = require 'mongoose'

module.exports = (app)->

  app.get '/api/menu/list', (req, res)->
    id = req.query.id
    query = {disabled:false}
    query.clients = id
    query.end_date = $gt:new Date()
    Menu.find(query)
    .select('_id updated_at end_date quality type')
    .sort(end_date:1)
    .exec (err, result)->
      if err
        Error err, res
      else
        menu = result
        if menu.list
          menu.list.forEach (time)->
            time.songs.sort (a, b)->
              return a.index-b.index
        res.json status:true, results:result

  saveMenu = (id, callback)->
    Menu.findById(id)
    .select('name list begin_date end_date quality dm_list type')
    .populate('list.songs.song', 'name url duration')
    .populate('dm_list.dm', 'name url duration')
    .exec (err, result)->
      extra = new qiniu.io.PutExtra()
      putPolicy = new qiniu.rs.PutPolicy('yfcdn:'+id+'.json')
      token = putPolicy.token()
      qiniu.io.put token, id+'.json', JSON.stringify(result), extra, (err, result)->
        if !err
          logger.trace id+'.json'
          callback true
        else
          logger.error err
          callback false

  app.get '/menu', auth.isAuthenticated(), (req, res)->
    res.render 'menu'

  app.get '/menu/report/:id/:report', auth.isAuthenticated(), (req, res)->
    name = req.params.report
    id = req.params.id
    if name.indexOf('xlsx') == -1 || !id
      return res.json status:false, result:'名称不对'
    Menu.findById(id)
    .select('name list begin_date end_date')
    .populate('list.songs.song', 'name artist duration tags')
    .exec (err, result)->
      data = []
      data.push(['歌单名称','开始日期', '结束日期'])
      data.push([result.name,
                 moment(result.begin_date).format('YYYY-MM-DD'),
                 moment(result.end_date).format('YYYY-MM-DD')
      ])
      data.push([])
      result.list.forEach (list)->
        songs = list.songs
        if !songs || !songs.lengt
          return false
        data.push(['时段名称','开始时间','结束时间'])
        list.name = '' unless list.name
        list.begin = '' unless list.begin
        list.end = '' unless list.end
        data.push([list.name,list.begin,list.end])
        data.push(['播放时间', '曲目名称', '歌手名称','播放时长','风格标签','允许循环'])
        begin = list.begin
        if !begin
          return
        i = 0
        h = begin.split(':')[0]
        m = begin.split(':')[1]
        time = moment(hour:parseInt(h),minute:parseInt(m))
        while i < songs.length
          allow = songs[i].allow_circle
          song = songs[i].song
          song.time = time.format('HH:mm:ss')
          if song.duration
            time.add 's', song.duration
          else
            song.duration = 0
          m = moment(second:song.duration).minutes()
          m = '0'+m if m<10
          s = moment(second:song.duration).seconds()
          s = '0'+s if s<10
          song.name = '' unless song.name
          song.artist = '' unless song.artist
          song.tags = [] unless song.tags
          data.push([song.time, song.name, song.artist, m+':'+s,song.tags.join(','), allow])
          i++
      buffer = xlsx.build
        worksheets:["name":result.name, "data":data]
        defaultFontName: 'Arial',defaultFontSize: 12
      res.send buffer

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
    query.type = data.type

    ep = new EventProxy()
    ep.fail (err)->
      Error err, res

    ep.all 'menu', 'count', (menu, count)->
      if menu.list
        menu.list.forEach (time)->
          time.songs.sort (a, b)->
            return a.index-b.index
      res.json status:true, results:menu, count:count

    Menu.count query, ep.done 'count'
    Menu.find(query)
    .populate('creator', 'username')
    .populate('updator', 'username')
    .populate('list.songs.song', 'name duration tags')
    .populate('dm_list.dm', 'name duration')
    .sort('created_at':-1)
    .limit(data.perPage)
    .skip(data.perPage*(data.page-1))
    .exec ep.done 'menu'

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
      if err
        Error err, res
      else
        updateTags result.tags
        saveMenu result.id, (value)->
          if value
            res.json status:true, results:result
          else
            res.json status:false, results:'保存歌单失败'