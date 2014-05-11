/**
 * User: mani
 * Date: 14-3-13
 * Time: PM7:00
 */

module.exports = function(err, res){
    if(err){
        res.json({status: false, results:'系统错误：'+err});
    }
}

