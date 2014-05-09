Mongoose = require 'mongoose'

require './sms'
require './manager'
require './dict'

module.exports = {
  SMS : Mongoose.model "SMS"
  Manager : Mongoose.model "Manager"
  Dict : Mongoose.model 'Dict'
}