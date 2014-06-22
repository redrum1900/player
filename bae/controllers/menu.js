// Generated by CoffeeScript 1.7.1
(function() {
  var Client, Dict, EventProxy, Manager, Menu, SMS, Song, UpdateObject, auth, logger, models, moment, qiniu, xlsx;

  auth = require('../lib/auth');

  models = require('../models');

  Manager = models.Manager;

  Client = models.Client;

  Dict = models.Dict;

  SMS = models.SMS;

  Song = models.Song;

  Menu = models.Menu;

  moment = require('moment');

  UpdateObject = require('../lib/utils').updateObject;

  qiniu = require('qiniu');

  logger = require('log4js').getLogger('Menu');

  xlsx = require('node-xlsx');

  EventProxy = require('eventproxy');

  module.exports = function(app) {
    var saveMenu, updateTags;
    app.get('/api/menu/list', function(req, res) {
      var id, query;
      id = req.query.id;
      query = {
        disabled: false
      };
      query.clients = id;
      query.end_date = {
        $gt: new Date()
      };
      return Menu.find(query).select('_id updated_at end_date quality type').sort({
        end_date: 1
      }).exec(function(err, result) {
        var menu;
        if (err) {
          return Error(err, res);
        } else {
          menu = result;
          if (menu.list) {
            menu.list.forEach(function(time) {
              return time.songs.sort(function(a, b) {
                return a.index - b.index;
              });
            });
          }
          return res.json({
            status: true,
            results: result
          });
        }
      });
    });
    saveMenu = function(id, callback) {
      return Menu.findById(id).select('name list begin_date end_date quality dm_list type').populate('list.songs.song', 'name url duration').populate('dm_list.dm', 'name url duration').exec(function(err, result) {
        var extra, putPolicy, token;
        console.log(result);
        extra = new qiniu.io.PutExtra();
        putPolicy = new qiniu.rs.PutPolicy('yfcdn:' + id + '.json');
        token = putPolicy.token();
        return qiniu.io.put(token, id + '.json', JSON.stringify(result), extra, function(err, result) {
          if (!err) {
            logger.trace(id + '.json');
            return callback(true);
          } else {
            logger.error(err);
            return callback(false);
          }
        });
      });
    };
    app.get('/menu', auth.isAuthenticated(), function(req, res) {
      return res.render('menu');
    });
    app.get('/menu/report/:id/:report', auth.isAuthenticated(), function(req, res) {
      var id, name;
      name = req.params.report;
      id = req.params.id;
      if (name.indexOf('xlsx') === -1 || !id) {
        return res.json({
          status: false,
          result: '名称不对'
        });
      }
      return Menu.findById(id).select('name list begin_date end_date').populate('list.songs.song', 'name artist duration tags').exec(function(err, result) {
        var buffer, data;
        data = [];
        data.push(['歌单名称', '开始日期', '结束日期']);
        data.push([result.name, moment(result.begin_date).format('YYYY-MM-DD'), moment(result.end_date).format('YYYY-MM-DD')]);
        data.push([]);
        result.list.forEach(function(list) {
          var allow, begin, h, i, m, s, song, songs, time, _results;
          songs = list.songs;
          if (!songs || !songs.lengt) {
            return false;
          }
          data.push(['时段名称', '开始时间', '结束时间']);
          if (!list.name) {
            list.name = '';
          }
          if (!list.begin) {
            list.begin = '';
          }
          if (!list.end) {
            list.end = '';
          }
          data.push([list.name, list.begin, list.end]);
          data.push(['播放时间', '曲目名称', '歌手名称', '播放时长', '风格标签', '允许循环']);
          begin = list.begin;
          if (!begin) {
            return;
          }
          i = 0;
          h = begin.split(':')[0];
          m = begin.split(':')[1];
          time = moment({
            hour: parseInt(h),
            minute: parseInt(m)
          });
          _results = [];
          while (i < songs.length) {
            allow = songs[i].allow_circle;
            song = songs[i].song;
            song.time = time.format('HH:mm:ss');
            if (song.duration) {
              time.add('s', song.duration);
            } else {
              song.duration = 0;
            }
            m = moment({
              second: song.duration
            }).minutes();
            if (m < 10) {
              m = '0' + m;
            }
            s = moment({
              second: song.duration
            }).seconds();
            if (s < 10) {
              s = '0' + s;
            }
            if (!song.name) {
              song.name = '';
            }
            if (!song.artist) {
              song.artist = '';
            }
            if (!song.tags) {
              song.tags = [];
            }
            data.push([song.time, song.name, song.artist, m + ':' + s, song.tags.join(','), allow]);
            _results.push(i++);
          }
          return _results;
        });
        buffer = xlsx.build({
          worksheets: [
            {
              "name": result.name,
              "data": data
            }
          ],
          defaultFontName: 'Arial',
          defaultFontSize: 12
        });
        return res.send(buffer);
      });
    });
    updateTags = function(tags) {
      if (tags) {
        return Dict.findOne({
          'key': 'MenuTags'
        }, function(err, dic) {
          if (dic) {
            if (dic.list) {
              tags.forEach(function(tag) {
                if (dic.list.indexOf(tag) === -1) {
                  return dic.list.addToSet(tag);
                }
              });
            } else {
              dic.list = tags;
            }
          } else {
            dic = new Dict({
              key: 'MenuTags',
              list: tags
            });
          }
          return dic.save();
        });
      }
    };
    app.get('/menu/list', auth.isAuthenticated(), function(req, res) {
      var arr, data, ep, query, tags;
      data = req.query;
      query = {};
      if (data.name) {
        query = {
          'name': new RegExp(data.name, 'i')
        };
      }
      tags = data.tags;
      if (tags) {
        arr = tags.split(',');
        query.tags = {
          $all: arr
        };
      }
      query.type = data.type;
      ep = new EventProxy();
      ep.fail(function(err) {
        return Error(err, res);
      });
      ep.all('menu', 'count', function(menu, count) {
        if (menu.list) {
          menu.list.forEach(function(time) {
            return time.songs.sort(function(a, b) {
              return a.index - b.index;
            });
          });
        }
        return res.json({
          status: true,
          results: menu,
          count: count
        });
      });
      Menu.count(query, ep.done('count'));
      return Menu.find(query).populate('creator', 'username').populate('updator', 'username').populate('list.songs.song', 'name duration tags').populate('dm_list.dm', 'name duration').sort({
        'created_at': -1
      }).limit(data.perPage).skip(data.perPage * (data.page - 1)).exec(ep.done('menu'));
    });
    app.post('/menu/update', auth.isAuthenticated(), function(req, res) {
      var data;
      data = req.body;
      return Menu.findById(data._id, function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          UpdateObject(result, data);
          result.updator = req.user;
          console.log(result.list[0].songs);
          return result.save(function(err, result) {
            if (err) {
              return Error(err, res);
            } else {
              updateTags(result.tags);
              return saveMenu(result.id, function(value) {
                if (value) {
                  return res.json({
                    status: true,
                    results: result
                  });
                } else {
                  return res.json({
                    status: false,
                    results: '保存歌单失败'
                  });
                }
              });
            }
          });
        }
      });
    });
    app.post('/menu/update/status', auth.isAuthenticated(), function(req, res) {
      var data;
      data = req.body;
      return Menu.findByIdAndUpdate(data._id, {
        $set: {
          disabled: data.disabled
        }
      }, function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          return res.json({
            status: true,
            result: result
          });
        }
      });
    });
    return app.post('/menu/add', auth.isAuthenticated(), function(req, res) {
      var data, menu;
      data = req.body;
      menu = new Menu(data);
      menu.creator = req.user;
      return menu.save(function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          updateTags(result.tags);
          return saveMenu(result.id, function(value) {
            if (value) {
              return res.json({
                status: true,
                results: result
              });
            } else {
              return res.json({
                status: false,
                results: '保存歌单失败'
              });
            }
          });
        }
      });
    });
  };

}).call(this);

//# sourceMappingURL=menu.map
