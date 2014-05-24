// Generated by CoffeeScript 1.7.1
(function() {
  var Client, Dict, Manager, Menu, SMS, Song, UpdateObject, auth, logger, models, qiniu;

  auth = require('../lib/auth');

  models = require('../models');

  Manager = models.Manager;

  Client = models.Client;

  Dict = models.Dict;

  SMS = models.SMS;

  Song = models.Song;

  Menu = models.Menu;

  UpdateObject = require('../lib/utils').updateObject;

  qiniu = require('qiniu');

  logger = require('log4js').getLogger('Menu');

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
      return Menu.find(query).select('_id updated_at end_date quality').sort({
        end_date: 1
      }).exec(function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          return res.json({
            status: true,
            results: result
          });
        }
      });
    });
    saveMenu = function(id, callback) {
      return Menu.findById(id).select('name list begin_date end_date quality').populate('list.songs.song', 'name cover url duration').exec(function(err, result) {
        var extra, putPolicy, token;
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
      var arr, data, query, tags;
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
      return Menu.find(query).populate('creator', 'username').populate('updator', 'username').populate('list.songs.song', 'name duration').sort({
        'created_at': -1
      }).limit(data.perPage).skip(data.perPage * (data.page - 1)).exec(function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          return res.json({
            status: true,
            results: result
          });
        }
      });
    });
    app.post('/menu/update', auth.isAuthenticated(), function(req, res) {
      var data;
      data = req.body;
      return Menu.findById(data._id, function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          UpdateObject(result, data);
          console.log(data);
          result.updator = req.user;
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
        console.log('save menu', err, result);
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
