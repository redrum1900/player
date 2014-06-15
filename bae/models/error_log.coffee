Mongoose = require 'mongoose'
Schema = Mongoose.Schema

ErrorLogSchema = new Schema
  client:type:Schema.Types.ObjectId,ref:'Client'
  url:String
  created_at:String

ErrorLogSchema.index client:1,created_at:-1

Mongoose.model 'ErrorLog', ErrorLogSchema