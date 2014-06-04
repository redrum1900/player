Mongoose = require 'mongoose'

require './sms'
require './manager'
require './dict'
require './client'
require './song'
require './menu'
require './dm'
require './log'

module.exports = {
  SMS : Mongoose.model "SMS"
  Manager : Mongoose.model "Manager"
  Dict : Mongoose.model 'Dict'
  Client : Mongoose.model 'Client'
  Song : Mongoose.model 'Song'
  Menu : Mongoose.model 'Menu'
  DM : Mongoose.model 'DM'
  Log : Mongoose.model 'Log'
  updateTags : (key, tags)->
    if tags
      Dict = module.exports.Dict
      Dict.findOne
        key:key
        (err, dic) ->
          if dic
            if dic.list
              tags.forEach (tag) ->
                dic.list.addToSet tag if dic.list.indexOf(tag) == -1
            else
              dic.list = tags
          else
            dic = new Dict(key:key,list:tags)
          dic.save()
}