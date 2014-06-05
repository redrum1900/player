Mongoose = require 'mongoose'
Schema = Mongoose.Schema

SongSchema = new Schema
  name:type:String,index:true,required:true
  cover:String
  url:String
  size:Number
  duration:Number
  tags:type:[String],index:true
  artist:String
  album:String
  company:String
  writer:String   #词作者
  composer:String #曲作者
  right_date:String #版权到期
  published_at:String #发行年份
  disabled:type:Boolean,default:false
  creator:type:Schema.Types.ObjectId,ref:"Manager"
  updator:type:Schema.Types.ObjectId,ref:"Manager"

Timestamps = require('mongoose-times')
SongSchema.plugin Timestamps, created:"created_at", lastUpdated:"updated_at"

Mongoose.model 'Song', SongSchema