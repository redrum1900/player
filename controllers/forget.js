'use strict';

var Mail = require('../lib/email');
var Manager = require('../models').Manager;
var bcrypt =require('bcrypt');

module.exports = function (app) {


    app.get('/forget', function (req, res) {
        res.render('forget');
    });

    app.post('/forget', function(req, res){
        var usernameOrEmail = req.body.usernameOrEmail;
        var query = usernameOrEmail.indexOf('@') == -1 ? {username:usernameOrEmail} : {email:usernameOrEmail};

        Manager.findOne(query, function (err, result) {
            if(err){
                res.render('forget', {message:err});
            }else if(result){
                var domain = 'http://'+req.headers.host;
                bcrypt.genSalt(10, function(err, salt) {
                    if(err){
                        res.render('forget', {message:'重置密码邮件发送失败，请再试一次'});
                        return;
                    }
                    bcrypt.hash(new Date().toISOString(), salt, function(err, hash) {
                        console.log(err, hash);
                        if(hash){
                            result.reset_token = hash;
                            result.save(function(err, result){
                                if(result){
                                    Mail.sendMail({
                                        from: '乐府时代 <support@iiiui.com>',
                                        to: result.username + ' <'+result.email+'>',
                                        subject:'密码重置',
                                        headers: {
                                            'X-Laziness-level': 1000
                                        },
                                        html:'<a href="'+domain+'/reset?token='+result.reset_token+'">点击重置密码</a>'
                                    }, function(result){
                                        if(result)
                                            res.render('forget', {message:'重置密码邮件发送成功，请登录邮箱查收'});
                                        else
                                            res.render('forget', {message:'重置密码邮件发送失败，请再试一次'});
                                    })
                                }else{
                                    res.render('forget', {message:'重置密码邮件发送失败，请再试一次'});
                                }
                            })
                        }
                    });
                });
            }else{
                res.render('forget', {message:'该用户不存在'});
            }
        });
    })

};
