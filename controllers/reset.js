'use strict';

var Manager = require('../models').Manager;

module.exports = function (app) {

    app.post('/reset', function (req, res) {
        var token = req.cookies.token;
        var pwd = req.body.password;
        var repwd = req.body.repassword;
        if(pwd != repwd){
            res.render('reset', {message:'两次密码输入不一直，请重新输入'});
            return;
        }else if(!pwd){
            res.render('reset', {message:'请输入密码'});
            return;
        }
        console.warn(token, pwd);
        if(token){
            Manager.findOne({reset_token: token}, function (err, result) {
                if(result){
                    result.password = pwd;
                    result.reset_token = '';
                    result.lockUntil = 0;
                    result.save(function(err, result){
                        console.log(result);
                        if(result){
                            res.render('index', {message:'重置密码成功'});
                        }else{
                            res.render('reset', {message:'重置失败，请稍后再试'+err});
                        }
                    })
                }else if(err){
                    res.render('reset', {message:'重置失败，请稍后再试'+err});
                }else{
                    res.redirect("/errors/404");
                }
            });
        }else{
            res.redirect("/errors/404");
        }
    });

    app.get('/reset', function (req, res) {

        var token = req.query.token;
        if(token){
            Manager.findOne({reset_token: token}, function (err, result) {
                if(result){
                    console.log(token, result.reset_token);
                    res.render('reset', {token:token});
                }else if(err){
                    res.render('reset', {message:'出问题了，请稍后再试'+err});
                }else{
                    res.redirect("/errors/404");
                }
            });
        }else{
            res.redirect("/errors/404");
        }


    });

};
