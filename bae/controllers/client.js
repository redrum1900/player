// Generated by CoffeeScript 1.7.1
(function() {
  var Error, EventProxy, Redis, SMS, UpdateObject, User, auth, models, updateTags;

  models = require('../models');

  User = models.Client;

  auth = require('../lib/auth');

  Error = require('../lib/error');

  UpdateObject = require('../lib/utils').updateObject;

  Redis = require('../lib/database/redis');

  SMS = require('../lib/sms');

  EventProxy = require('eventproxy');

  updateTags = models.updateTags;

  module.exports = function(app) {
    app.get('/clients', auth.isAuthenticated(), function(req, res) {
      return res.render('clients');
    });
    app.post('/api/user/login', function(req, res) {
      var data, ep;
      data = req.body;
      if (!data.udid && (!data.mobile || !data.code)) {
        return res.json({
          status: false,
          result: 'udid或手机号&验证码不能为空'
        });
      }
      ep = new EventProxy();
      ep.once('save', function(user) {
        return Redis.setUser(user, function(ret) {
          if (ret) {
            return reply(null, user, res);
          } else {
            return reply('服务出错，请稍后再试', null, res);
          }
        });
      });
      if (data.mobile) {
        return User.getAuthenticated(data.mobile, data.code, function(err, result) {
          if (err) {
            return reply(err, result, res);
          } else {
            return ep.emit('save', result);
          }
        });
      } else {
        return User.findOne({
          udid: data.udid
        }, '-last_login_time -signed_in_times -updated_at -password -come_from -loginAttempts -lockUntil -creator -updator', function(err, result) {
          var user;
          if (err) {
            return reply(err, result, res);
          } else if (result) {
            result.signed_in_times++;
            result.save();
            return ep.emit('save', result);
          } else {
            user = new User(data);
            user.come_from = 'app';
            return user.save(function(err, result) {
              return ep.emit('save', result);
            });
          }
        });
      }
    });
    app.post('/api/user/code', function(req, res) {
      var data;
      data = req.body;
      if (!data.mobile || !data.udid) {
        return res.json({
          status: false,
          result: '手机号或设备号不能为空'
        });
      }
      return Redis.getCode(data.mobile, function(result) {
        var code, ep;
        if (result) {
          return res.json({
            status: false,
            result: '需要60秒后才能再试'
          });
        } else {
          ep = new EventProxy();
          code = Math.ceil(Math.random() * 899999) + 100000;
          ep.once('send', function() {
            SMS.send(data.mobile, '联想移动用户体验验证码：' + code, function(result) {});
            if (result.status) {
              Redis.setCode(data.mobile, code);
              return res.json({
                status: true
              });
            } else {
              return res.json({
                status: false
              });
            }
          });
          return User.findOne({
            mobile: data.mobile
          }, function(err, result) {
            if (err) {
              return reply(err, result, res);
            } else if (result) {
              result.password = code;
              return result.save(function(err, result) {
                if (err) {
                  return res.json({
                    status: false
                  });
                } else {
                  return ep.emit('send');
                }
              });
            } else {
              return User.findOne({
                uidi: data.udid
              }, function(err, result) {
                var user;
                if (err) {
                  return reply(err, result, res);
                } else if (result) {
                  if (!(result.mobile || result.mobile === data.mobile)) {
                    result.password = code;
                    result.mobile = data.mobile;
                    return result.save(function(err, result) {
                      if (err) {
                        return reply(err, result, res);
                      } else {
                        return ep.emit('send');
                      }
                    });
                  } else {
                    user = new User(data);
                    user.come_from = 'app';
                    user.password = code;
                    return user.save(function(err, result) {
                      if (err) {
                        return reply(err, result, res);
                      } else {
                        return ep.emit('send');
                      }
                    });
                  }
                } else {
                  return res.json({
                    status: false,
                    result: '用户设备尚未初始化'
                  });
                }
              });
            }
          });
        }
      });
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
    app.post('/user/update/status', auth.isAuthenticated(), function(req, res) {
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
