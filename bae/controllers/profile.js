'use strict';


var auth = require('../lib/auth');
var Manager = require('../models').Manager;
var Apply = require('../models/apply');
var Mail = require('../lib/email');
var bcrypt =require('bcrypt');

module.exports = function (app) {

    app.get('/profile', auth.isAuthenticated(), function (req, res) {

        res.render('profile');

    });

    app.post('/apply/handler', auth.isAuthenticated(0), function (req, res) {
        var data = req.body;
        delete data['_id'];
        console.log(data);
        Apply.findOneAndUpdate({username: data.username}, data, function (err, result) {
            console.log('Applied:'+result);
            if(data.approved){
                var password = Math.ceil(Math.random()*1000000);
                console.log(password);
                var m = new Manager();
                m.username = data.username;
                m.email = data.email;
                m.password = password;
                m.approved = true;

                var domain = 'http://'+req.headers.host;
                bcrypt.genSalt(10, function(err, salt) {
                    if(err){
                        res.json({status:false, results:'操作失败，请再试一次'});
                        return;
                    }
                    bcrypt.hash(new Date().toISOString(), salt, function(err, hash) {
                        if(hash){
                            m.reset_token = hash;
                            m.save(function(err, result){
                                if(result){
                                    Mail.sendMail({
                                        to: result.username + ' <'+result.email+'>',
                                        subject:'您的申请已通过',
                                        html:'您可以直接用密码 '+password+' 登录或 <a href="'+domain+'/reset?token='+result.reset_token+'">点击重置密码</a>'
                                    }, function(result){
                                        if(result)
                                            res.json({status:true, results:'操作成功，已发送申请成功的邮件给申请者'});
                                        else
                                            res.json({status:false, results:'操作失败，邮件发送失败'});
                                    })
                                }else{
                                    res.json({status:false, results:'操作失败，请再试一次'});
                                }
                            })
                        }
                    });
                });
            }else{
                res.json({status: true});
            }
        });
    });

    app.post('/manager/update', auth.isAuthenticated(0), function (req, res) {
        var data = req.body;
        console.log(data);
        Manager.findOneAndUpdate({username: data.username}, {$set: {disabled: data.disabled}}, function (err, result) {
            if(err){
                res.json({status:false, results:'操作失败，请再试一次'});
            }else{
                res.json({status: true});
            }
        });
    });

    app.get('/manager/list', auth.isAuthenticated(0), function(req, res){
        Manager.find({}, 'username email signed_in_times disabled',function (err, results) {
            if(err){
                res.json({status: false, results: err});
            }else{
                res.json({status: true, results: results});
            }
        });
    })

};