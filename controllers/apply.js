'use strict';


var Apply = require('../models/apply');
var Manager = require('../models/manager');
var Joi = require('joi');
var validator = require('../lib/validator');
var auth = require('../lib/auth');

module.exports = function (app) {

    var applySchema = {
        username:Joi.string().min(1).max(18),
        email:Joi.string().email(),
        labels:{username:'用户名', email:'邮箱'}
    }

    app.get('/apply/list', auth.isAuthenticated(0), function (req, res) {
        Apply.find({}, 'username email approved handled', function (err, result) {
            if(err){
                res.json({status: false, results: err});
            }else{
                res.json({status: true, results: result});
            }
        });

    });

    app.get('/apply', function (req, res) {

        res.render('apply');

    });

    app.post('/apply', function (req, res) {

        var data = req.body;

        var err = validator.validate(data, applySchema);
        if(err){
            res.render('apply', {message:err});
            return;
        }

        if(data.username.indexOf('@') != -1){
            res.render('apply', {message:'用户名不能有@符'});
            return;
        }

        var apply = new Apply(data);

        Manager.findOne({username: data.username}, function (err, result) {
            if(err){
                res.render('apply', {message:err});
            }else if(!result){
                apply.save(function (err, result) {
                    if (err) {
                        res.render('apply', {message: '程序出错了，请稍后再试'});
                    } else {
                        res.render('apply', {message: '您的申请已提交，审核结果会发送到您邮箱，请留意查收'});
                    }
                })
            }else{
                res.render('apply', {message: '该用户已存在，请尝试新用户'});
            }
        });
    });

};
