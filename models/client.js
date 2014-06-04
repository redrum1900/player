// Generated by CoffeeScript 1.7.1
(function() {
  var Bcrypt, ClientSchema, LOCK_TIME, MAX_LOGIN_ATTEMPTS, Mongoose, SALT_WORK_FACTOR, Schema, Timestamps;

  Mongoose = require('mongoose');

  Schema = Mongoose.Schema;

  Bcrypt = require('bcrypt');

  SALT_WORK_FACTOR = 10;

  MAX_LOGIN_ATTEMPTS = 5;

  LOCK_TIME = 2 * 60 * 60 * 1000;

  ClientSchema = new Schema({
    username: {
      type: String,
      required: true,
      index: {
        unique: true
      }
    },
    password: {
      type: String,
      required: true
    },
    email: {
      type: String,
      index: {
        unique: true,
        sparse: true
      }
    },
    mobile: {
      type: Number,
      index: {
        unique: true,
        sparse: true
      }
    },
    tags: {
      type: [String],
      index: true
    },
    broadcasts: [
      {
        name: String,
        playTime: String,
        url: String,
        repeat: Number,
        interval: Number,
        duration: Number
      }
    ],
    man: String,
    man_info: String,
    loginAttempts: {
      type: Number,
      "default": 0
    },
    lockUntil: Number,
    last_login: Date,
    signed_in_times: {
      type: Number,
      "default": 1
    },
    code: Number,
    disabled: {
      type: Boolean,
      "default": false
    },
    parent: {
      type: Schema.Types.ObjectId,
      ref: 'Client'
    },
    creator: {
      type: Schema.Types.ObjectId,
      ref: "Manager"
    },
    updator: {
      type: Schema.Types.ObjectId,
      ref: "Manager"
    }
  });

  ClientSchema.virtual('isLocked').get(function() {
    return !!(this.lockUntil && this.lockUntil > Date.now());
  });

  Timestamps = require('mongoose-times');

  ClientSchema.plugin(Timestamps, {
    created: "created_at",
    lastUpdated: "updated_at"
  });

  ClientSchema.pre('save', function(next) {
    var client;
    client = this;
    if (!client.isModified('password')) {
      return next();
    }
    return Bcrypt.genSalt(SALT_WORK_FACTOR, function(err, salt) {
      if (err) {
        return next(err);
      }
      return Bcrypt.hash(client.password, salt, function(err, hash) {
        if (err) {
          return next(err);
        }
        client.password = hash;
        return next();
      });
    });
  });

  ClientSchema.methods.comparePassword = function(password, callback) {
    return Bcrypt.compare(password, this.password, function(err, isMatch) {
      if (err) {
        return callback(err);
      } else {
        return callback(null, isMatch);
      }
    });
  };

  ClientSchema.methods.incLoginAttempts = function(callback) {
    var update;
    if (this.lockUntil && this.lockUntil < Date.now()) {
      return this.update({
        $set: {
          loginAttempts: 1
        },
        $unset: {
          lockUntil: 1
        }
      }, callback);
    }
    update = {
      $inc: {
        loginAttempts: 1
      }
    };
    if (this.loginAttempts + 1 >= MAX_LOGIN_ATTEMPTS && !this.isLocked) {
      update.$set = {
        lockUntil: Date.now() + LOCK_TIME
      };
    }
    return this.update(update, callback);
  };

  ClientSchema.statics = {
    getAuthenticated: function(usernameOrMobileOrEmail, password, callback) {
      var query;
      query = {};
      if (usernameOrMobileOrEmail.indexOf('@') !== -1) {
        query.email = usernameOrMobileOrEmail;
      } else if (parseInt(usernameOrMobileOrEmail) > 0 && usernameOrMobileOrEmail.length === 11) {
        query.mobile = usernameOrMobileOrEmail;
      } else {
        query.username = usernameOrMobileOrEmail;
      }
      return this.findOne(query, function(err, result) {
        if (err) {
          return callback(err);
        }
        if (!result) {
          return callback('用户不存在');
        }
        if (result.isLocked) {
          return result.incLoginAttempts(function(err) {
            if (err) {
              return callback(err);
            } else {
              return callback('您密码错误超过限制，已禁止登录，请两小时后再试或通过手机或邮箱找回密码');
            }
          });
        }
        return result.comparePassword(password, function(err, isMatch) {
          if (err) {
            return callback(err);
          }
          if (isMatch) {
            if (result.disabled) {
              return callback('抱歉，您的账号已被禁用，请联系管理人员');
            }
            result.last_login_time = new Date();
            result.signed_in_times++;
            if (!result.loginAttempts && !result.lockUntil) {
              result.save();
              return callback(null, result);
            } else {
              result.loginAttempts = 0;
              result.lockUntil = 0;
              return result.save(function(err, result) {
                if (err) {
                  return callback(err);
                }
                return callback(null, result);
              });
            }
          } else {
            return result.incLoginAttempts(function(err) {
              if (err) {
                return callback(err);
              }
              return callback('密码错误');
            });
          }
        });
      });
    }
  };

  Mongoose.model('Client', ClientSchema);

}).call(this);

//# sourceMappingURL=client.map
