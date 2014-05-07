/**
 * User: mani
 * Date: 14-3-13
 * Time: PM7:00
 */

module.exports = function(err, res){
    if(err){
        res.json({status: false, error:'出错啦，请稍后再试'});
    }
}

