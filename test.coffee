qiniu = require 'qiniu'

qiniu.conf.ACCESS_KEY = 'xyGeW-ThOyxd7OIkwVKoD4tHZmX0K0cYJ6g1kq4J';
qiniu.conf.SECRET_KEY = 'bJSwo1--7pa-HD3g7fFHaI6e_TOYP1NCk3Z7XM7G';
mg = require './lib/database/mongo'
mg.config({host: 'localhost', database: 'yuefu'});
Menu = require('./models').Menu
xlsx = require 'node-xlsx'
fs = require 'fs'
client = new qiniu.rs.Client()
moment = require 'moment'

data =

Menu.findById("53908926fc534a1955a3d960")
.select('name list begin_date end_date')
.populate('list.songs.song', 'name duration')
.exec (err, result)->
  data = []
  data.push(['歌单名称','开始日期', '结束日期'])
  data.push([result.name,
             moment(result.begin_date).format('YYYY-MM-DD'),
             moment(result.end_date).format('YYYY-MM-DD')
  ])
  data.push([])
  result.list.forEach (list)->
    data.push(['时段名称','开始时间','结束时间'])
    data.push([list.name,list.begin,list.end])
    data.push(['播放时间', '曲目名称', '歌手名称','播放时长','允许循环'])
    songs = list.songs
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
      song.artist = '' unless song.artist
      m = moment(second:song.duration).minutes()
      s = moment(second:song.duration).seconds()
      data.push([song.time, song.name, song.artist, m+':'+s, allow])
      i++
    buffer = xlsx.build
      worksheets:["name":result.name, "data":data]
      defaultFontName: 'Arial',defaultFontSize: 12
    fs.writeFile(__dirname+'/test.xlsx',buffer, 'utf-8', (err)->
      console.log 'saved',err, data.length
    )