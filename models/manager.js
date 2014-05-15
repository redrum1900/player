var Mongoose = require('mongoose');
var Schema = Mongoose.Schema;
var Bcrypt = require('bcrypt');
var SALT_WORK_FACTOR = 10;
var MAX_LOGIN_ATTEMPTS = 6;
var LOCK_TIME = 2 * 60 * 60 * 1000;

var ManagerSchema = new Schema({
    username: {required: true, type: 'String', index: {unique:true}},
    password: {type: 'String', required: true},
    email:{type:'String', required:true, index:true},
    role:{type:Number, required:true},
    loginAttempts: {type: Number, default: 0},
    lockUntil: Number,
    disabled:{type:Boolean, default:false},
    last_login_time: Date, //最近登陆时间
    signed_in_times: {type:Number, default:1}, //登陆次数
    reset_token:{type:String,index:true}
});

var Timestamps = require('mongoose-times');
ManagerSchema.plugin(Timestamps, {created: "created_at", lastUpdated: "updated_at"});

ManagerSchema.virtual('isLocked').get(function () {
    return !!(this.lockUntil && this.lockUntil > Date.now());
});

ManagerSchema.pre('save', function (next) {
    var user = this;
    // only hash the password if it has been modified (or is new)
    if (!user.isModified('password')) return next();

    // generate a salt
    Bcrypt.genSalt(SALT_WORK_FACTOR, function (err, salt) {
        if (err) return next(err);

        // hash the password using our new salt
        Bcrypt.hash(user.password, salt, function (err, hash) {
            if (err) return next(err);

            // set the hashed password back on our user document
            user.password = hash;
            next();
        });
    });
});

ManagerSchema.methods.comparePassword = function (candidatePassword, cb) {
    Bcrypt.compare(candidatePassword, this.password, function (err, isMath) {
        if (err) return cb(err);
        cb(null, isMath);
    })
};

ManagerSchema.methods.incLoginAttempts = function (cb) {
    // if we have a previous lock that has expired, restart at 1
    if (this.lockUntil && this.lockUntil < Date.now()) {
        return this.update({
            $set: { loginAttempts: 1 },
            $unset: { lockUntil: 1 }
        }, cb);
    }
    // otherwise we're incrementing
    var updates = { $inc: { loginAttempts: 1 } };
    // lock the account if we've reached max attempts and it's not locked already
    if (this.loginAttempts + 1 >= MAX_LOGIN_ATTEMPTS && !this.isLocked) {
        updates.$set = { lockUntil: Date.now() + LOCK_TIME };
    }
    return this.update(updates, cb);
};

var VERIFIED_EMAIL = 1,
    VERIFIED_PHONE = 2,
    VERIFIED_EMAIL_AND_PHONE = 3;

ManagerSchema.statics = {
    updateUser: function (user, callback) {
        this.findOneAndUpdate(user.id, user, callback);
    },
    getTopUsers : function(sum, callback){
        this.find()
            .sort({'win_times': -1})
            .select('-boughtGoods -__v -password -creator -updator -portrait -loginAttempts -last_login_time -signed_in_times -updated_at -created_at -_id')
            .limit(sum)
            .exec(callback);
    },
    getUsers: function (options, callback) {
        var perPage = options.perPage;
        var page = options.page;
        delete options.perPage;
        delete options.page;
        delete options.id;
        var q = {};
        if(options.info)
            q = {$or: [
                {'username': new RegExp(options.info, 'i')},
                {'company_name': new RegExp(options.info, 'i')}
            ]};
        this.find(q)
            .populate('creator', 'worker_id')
            .populate('updator', 'worker_id')
            .sort({'created_at': -1})
            .limit(perPage)
            .skip(perPage * (page - 1))
            .exec(callback);
    },
    getAuthenticated: function (username, password, cb) {
        var query = {username: username};
        this.findOne(query, function (err, user) {
            if (err) return cb(err);
            // make sure the user exists
            if (!user) {
                return cb(null, null, '该用户不存在');
            }

            // check if the account is currently locked
            if (user.isLocked) {
                // just increment login attempts if account is already locked
                return user.incLoginAttempts(function (err) {
                    if (err) return cb(err);
                    return cb(null, null, '您密码已错6次，请2小时后再尝试登录');
                });
            }

            // test for a matching password
            user.comparePassword(password, function (err, isMatch) {
                if (err) return cb(err);

                // check if the password was a match
                if (isMatch) {
                    if(user.disabled){
                        return cb(null, null, '您的账号已被禁用');
                    }
                    user.last_login_time = new Date();
                    if(!user.signed_in_times)
                        user.signed_in_times=0;
                    user.signed_in_times += 1;
                    user.save();
                    // if there's no lock or failed attempts, just return the user
                    if (!user.loginAttempts && !user.lockUntil) return cb(null, user);
                    // reset attempts and lock info
                    var updates = {
                        $set: { loginAttempts: 0 },
                        $unset: { lockUntil: 1 }
                    };
                    user.update(updates, function (err) {
                        if (err) return cb(err);
                        return cb(null, user);
                    });
                }else{
                    // password is incorrect, so increment login attempts before responding
                    user.incLoginAttempts(function (err) {
                        if (err) return cb(err);
                        return cb(null, null, '密码错误');
                    });
                }
            });
        });
    }
}

ManagerSchema.statics.verify = function (code, usefor, cb) {

};

Mongoose.model('Manager', ManagerSchema);
