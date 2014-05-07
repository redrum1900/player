/**
 * User: mani
 * Date: 14-3-13
 * Time: PM2:53
 */
var Joi = require('joi');

module.exports.validate = function(object, schema, option){
    if(!option)
        option = {allowUnknown:true};
    option.languagePath = __dirname+'/../locales/CN/zh/joi.json';
    var err = Joi.validate(object, schema, option);
    if(!err){
        return;
    }
    else{
        var labels = schema.labels;
        var message;
        if(labels){
            var path = err.details[0].path;
            message = err.message.replace(path, labels[path]);
        }else{
            message = err.message;
        }
        return message;
    }
}