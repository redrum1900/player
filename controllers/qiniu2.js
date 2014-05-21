/**
 * User: mani
 * Date: 14-3-17
 * Time: AM10:46
 */

var qiniu = require('qiniu');
//var UFile = require('../models/ufile');
var auth = require('../lib/auth');

module.exports = function(app){

    qiniu.conf.ACCESS_KEY = 'xyGeW-ThOyxd7OIkwVKoD4tHZmX0K0cYJ6g1kq4J';
    qiniu.conf.SECRET_KEY = 'bJSwo1--7pa-HD3g7fFHaI6e_TOYP1NCk3Z7XM7G';

    app.get('/upload/token', auth.isAuthenticated(), function (req, res) {
        var putPolicy = new qiniu.rs.PutPolicy('yfcdn');
        putPolicy.expires = 3600;
        var token = putPolicy.token();
        res.json({'uptoken':token})
    });

    app.get('/upload/token/mp3', auth.isAuthenticated(), function (req, res) {
        var putPolicy = new qiniu.rs.PutPolicy('yfcdn');
        putPolicy.expires = 3600;
        putPolicy.persistentOps = 'avthumb/mp3/ab/192k;avthumb/mp3/ab/64k'
        var token = putPolicy.token();
        res.json({'uptoken':token})
    });

    app.post('/uploaded', function(req, res){
        console.log(req.body, req.headers);
        var ufile = new UFile(req.body);
        ufile.save(function(err, result){
            if(err){
                console.error(err);
                res.json({"success": false});
            }else{
                res.json({"success": true});
            }
        })
    })

}