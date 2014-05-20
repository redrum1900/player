var Mailer = require('nodemailer');
var logger = require('log4js').getLogger('Email');
var internals = {};

module.exports = {
    sendMail: function (mailOptions, callback) {

        mailOptions.from = '乐府管理系统 <support@iiiui.com>'
        mailOptions.headers = {'X-Laziness-level': 1000};

        internals.transport.sendMail(mailOptions, function (error, response) {
            if (error) {
                if(callback)
                    callback(false);
                logger.error('Sent email error: ' + error);
            } else {
                logger.trace('Sent mail: ' + response.message);
                if(callback)
                    callback(true);
            }
        });
    },

    config:function(config){
        internals.transport = Mailer.createTransport('SMTP', config);
        console.log('SMTP Configured!');
    }
};