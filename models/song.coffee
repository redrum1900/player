Mongoose = require 'mongoose'
Schema = Mongoose.Schema

SongSchema = new Schema
  name:type:String,index:true,required:true
  url:String
  tags:type:[String],index:true
  id3:Schema.Types.Mixed
  creator:type:Schema.Types.ObjectId,ref:"Manager"
  updator:type:Schema.Types.ObjectId,ref:"Manager"


Timestamps = require('mongoose-times')
SongSchema.plugin Timestamps, created:"created_at", lastUpdated:"updated_at"

#SongSchema.index 'tags', 1

Mongoose.model 'Song', SongSchema