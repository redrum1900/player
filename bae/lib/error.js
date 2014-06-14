/**
 * User: mani
 * Date: 14-3-13
 * Time: PM7:00
 */

var logger = require('log4js').getDefaultLogger()

module.exports = function(err, res){
    if(err){
        logger.error("Error:"+err);
        res.json({status: false, results:'系统错误：'+err});
    }
}

