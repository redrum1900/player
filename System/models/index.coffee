Mongoose = require 'mongoose'

require './sms'
require './manager'

module.exports = {
  SMS : Mongoose.model "SMS"
  Manager : Mongoose.model "Manager"
}