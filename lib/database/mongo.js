/**
 * User: mani
 * Date: 14-3-4
 * Time: PM5:55
 */
'use strict';
var mongoose = require('mongoose');
var url = 'mongodb://localhost/yuefu';

module.exports = {
    config: function (conf) {
        if(process.env.USER != 'mani'){
            url = conf
        }

        mongoose.set('debug', true);

        var db = mongoose.connection;

        db.on('connecting', function() {
            console.log('connecting to MongoDB...');
        });

        db.on('error', function(error) {
            console.error('Error in MongoDb connection: ' + error);
            mongoose.disconnect();
        });
        db.on('connected', function() {
            console.log('MongoDB connected!');
        });
        db.once('open', function() {
            console.log('MongoDB connection opened!');
        });
        db.on('reconnected', function () {
            console.log('MongoDB reconnected!');
        });
        db.on('disconnected', function() {
            console.log('MongoDB disconnected!');
            mongoose.connect(url, {server:{auto_reconnect:true}});
        });
        mongoose.connect(url, {server:{auto_reconnect:true}});
    }
};