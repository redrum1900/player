var Mailer = require('nodemailer');

var internals = {};

module.exports = {
    sendMail: function (mailOptions, callback) {

        mailOptions.from = '联想研究系统 <support@blossompavilion.com>'
        mailOptions.headers = {'X-Laziness-level': 1000};

        internals.transport.sendMail(mailOptions, function (error, response) {
            if (error) {
                if(callback)
                    callback(false);
                console.error('Sent email error: ' + error);
            } else {
                console.log('Sent mail: ' + response.message);
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