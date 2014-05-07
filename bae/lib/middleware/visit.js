/**
 * User: mani
 * Date: 14-3-4
 * Time: PM5:16
 */

'use strict';

module.exports = function(){
    var visited = 0;

    return function(req, res, next){
        visited ++;
        console.log('Visited: ' + visited);
        next();
    };
};
