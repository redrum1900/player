/**
 * User: mani
 * Date: 14-3-4
 * Time: PM5:55
 */
'use strict';
var mongoose = require('mongoose');

module.exports = {
    config: function (conf) {
        mongoose.connect('mongodb://' + conf.host + '/' + conf.database);
        var db = mongoose.connection;
        db.on('error', console.error.bind(console, 'connection error:'));
        db.once('open', function callback() {
            console.log('db connection open');
        });
    }
};