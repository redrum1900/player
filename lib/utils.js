/**
 * User: mani
 * Date: 14-3-10
 * Time: PM6:39
 */
exports.randomString = function(len) {
    var buf = []
        , chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
        , charlen = chars.length;

    for (var i = 0; i < len; ++i) {
        buf.push(chars[getRandomInt(0, charlen - 1)]);
    }

    return buf.join('');
};

exports.updateObject = function(result, data, excludeFields){
    var key;
    if(!excludeFields)
        excludeFields = [];
    excludeFields.push('creator', 'updator');
    for(key in data){
        if(excludeFields.indexOf(key) == -1)
            result[key] = data[key]
    }
}

function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}