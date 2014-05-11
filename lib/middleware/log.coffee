log4js = require 'log4js'

exports.logger = (options)->
  return log4js.connectLogger(log4js.getLogger("request"), options);