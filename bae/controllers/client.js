// Generated by CoffeeScript 1.7.1
(function() {
  var Error, EventProxy, Log, Redis, SMS, UpdateObject, User, auth, logger, models, updateTags;

  models = require('../models');

  User = models.Client;

  auth = require('../lib/auth');

  Error = require('../lib/error');

  UpdateObject = require('../lib/utils').updateObject;

  Redis = require('../lib/database/redis');

  SMS = require('../lib/sms');

  EventProxy = require('eventproxy');

  updateTags = models.updateTags;

  logger = require('log4js').getDefaultLogger();

  Log = models.Log;

  module.exports = function(app) {
    app.get('/clients', auth.isAuthenticated(), function(req, res) {
      return res.render('clients');
    });
    app.post('/api/user/login', function(req, res) {
      var data;
      data = req.body;
      if (!data.username || !data.password) {
        return res.json({
          status: false,
          results: '用户名或密码不能为空'
        });
      }
      return User.getAuthenticated(data.username, data.password, function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          return res.json({
            status: true,
            results: {
              id: result.id,
              broadcasts: result.broadcasts
            }
          });
        }
      });
    });
    app.get('/api/refresh', function(req, res) {
      var data, ep;
      data = req.query;
      if (!data.id) {
        logger.warn('no id to refresh', req.ip);
        return res.json({
          status: false
        });
      }
      ep = new EventProxy();
      ep.all('log', 'bro', 'menu', function(log, bro, menu) {});
      ep.fail(function(err) {
        return Error(err, res);
      });
      return Log.findOneAndUpdate();
    });
    app.get('/user/list', auth.isAuthenticated(), function(req, res) {
      var arr, data, query, tags;
      data = req.query;
      query = {};
      if (data.username) {
        query = {
          'username': new RegExp(data.username, 'i')
        };
      }
      tags = data.tags;
      if (tags) {
        arr = tags.split(',');
        query.tags = {
          $all: arr
        };
      }
      return User.find(query).populate('creator', 'username').populate('updator', 'username').populate('parent', 'username').sort({
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
    app.post('/user/update', auth.isAuthenticated(), function(req, res) {
      var data;
      data = req.body;
      data.updator = req.user._id;
      return User.findById(data._id, function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          UpdateObject(result, data);
          return result.save(function(err, result) {
            if (err) {
              return Error(err, res);
            } else {
              updateTags('ClientTags', result.tags);
              return res.json({
                status: true,
                results: result
              });
            }
          });
        }
      });
    });
    app.get('/user/parents', auth.isAuthenticated(), function(req, res) {
      var data;
      data = req.query;
      return User.find({
        parent: null
      }).populate('parent', 'username').select('username parent').exec(function(err, result) {
        return res.json({
          result: result
        });
      });
    });
    app.post('/user/update/status', auth.isAuthenticated(0), function(req, res) {
      var data;
      data = req.body;
      return User.findByIdAndUpdate(data._id, {
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
    return app.post('/user/add', auth.isAuthenticated(), function(req, res) {
      var code, data, user;
      data = req.body;
      if (data.parent) {
        data.username = data.parent.username + ':' + data.username;
        data.parent = data.parent._id;
      }
      if (data.username.indexOf('@') !== -1) {
        return res.json({
          status: false,
          results: '用户名不能有邮件@符号'
        });
      }
      user = new User(data);
      user.creator = req.user;
      code = Math.floor(Math.random() * 899999) + 100000;
      user.code = code;
      user.password = code;
      return user.save(function(err, result) {
        if (err) {
          return Error(err, res);
        } else {
          updateTags('ClientTags', result.tags);
          return res.json({
            status: true,
            results: result
          });
        }
      });
    });
  };

}).call(this);

//# sourceMappingURL=client.map
