'use strict';

global.debug = process.env.USER == 'mani'
global.reply = function(err, result, res){
    if(err){
        res.json({status: false, result: err});
    }else{
        res.json({status: true, result: result});
    }
}

if(!debug){
    var log4js = require('log4js');
    log4js.loadAppender('baev3-log');
    var options = {
        'user': '9RGMgDe0USUb1ODDnQgRBhN2',
        'passwd': 'xt6e5Qrx93m1ebGHUpxHh7qB4CjnlKti'
    }
    log4js.addAppender(log4js.appenders['baev3-log'](options));
}

var kraken = require('kraken-js'),
    mongo = require('./lib/database/mongo'),
    redis = require('./lib/database/redis'),
    mail = require('./lib/email'),
    passport = require('passport'),
    auth = require('./lib/auth'),
    Manager = require('./models').Manager,
    flash = require('connect-flash'),
    api_auth = require('./lib/middleware/api_auth'),
    sms = require('./lib/sms'),
    app = {}; 

require('./lib/helper-formatDate');

app.configure = function configure(nconf, next) {

    mongo.config(nconf.get('mongo'));
    redis.config(nconf.get('redis'));
    mail.config(nconf.get('email'));
    sms.config(nconf.get('sms'));

//    var u1 = new Manager({
//        username: 'admin',
//        password: '666666',
//        email:'mani95lisa@gmail.com',
//        role: 0
//    });
//    u1.save();

    passport.use(auth.localStrategy());

    passport.serializeUser(function (user, done) {
        done(null, user.id);
    });

    passport.deserializeUser(function (id, done) {
        Manager.findById(id, function (err, user) {
            done(null, user);
        });
    });

    next(null);
};


app.requestStart = function requestStart(server) {
    // Run before most express middleware has been registered.
};


app.requestBeforeRoute = function requestBeforeRoute(server) {
    // Run before any routes have been added.
//    server.use(language());
    server.use(passport.initialize());
    server.use(passport.session());
    server.use(flash());
    server.use(auth.injectUser);
    server.use(api_auth());
};

app.requestAfterRoute = function requestAfterRoute(server) {
    // Run after all routes have been added.
};

if (require.main === module) {
    kraken.create(app).listen(function (err) {
        if (err) {
            console.error(err.stack);
        }
    });
}

module.exports = app;
