Mongoose = require 'mongoose'

require './sms'
require './manager'
require './dict'
require './client'
require './song'
require './menu'

module.exports = {
  SMS : Mongoose.model "SMS"
  Manager : Mongoose.model "Manager"
  Dict : Mongoose.model 'Dict'
  Client : Mongoose.model 'Client'
  Song : Mongoose.model 'Song'
  Menu : Mongoose.model 'Menu'
}