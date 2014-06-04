Mongoose = require 'mongoose'
Schema = Mongoose.Schema

LogSchema = new Schema
  client:type:Schema.Types.ObjectId,ref:'Client'
  count:type:Number,default:0
  created_at:String
  updated_at:Date

LogSchema.index client:1,created_at:-1

Mongoose.model 'Log', LogSchema