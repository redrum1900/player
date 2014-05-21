/**
 * User: mani
 * Date: 14-3-13
 * Time: PM6:02
 */

'use strict';

var Redis = require('../database/redis');

module.exports = function(){

    //需要认证是否登录的接口请求
    var needAuthRoutes = [
//        '/api/upload/token'
//        '/api/user/login'
    ];

    return function(req, res, next){
        var path = req._parsedUrl.pathname;
        var id = req.method == 'GET' ? req.query.id : req.body.id;
        if(needAuthRoutes.indexOf(path) != -1){
            if(id){
                Redis.getUser(id, function (err, result) {
                    if (result) {
                        next();
                    } else if (err) {
                        res.json({status: false, result: '出错啦，请稍后再试', need_login:true});
                    } else {
                        res.json({status: false, result: '请登录后再试', need_login:true});
                    }
                });
            }else{
                res.json({status:false, result:'请登录后再试', need_login:true});
            }
        }else{
            if(id){
                Redis.getUser(id);
            }
            next();
        }
    }
}