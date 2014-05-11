Mongoose = require 'mongoose'
Schema = Mongoose.Schema

DictSchema = new Schema
  key:type:String, required:true, index:unique:true
  value:String
  list:[]


Timestamps = require('mongoose-times')
DictSchema.plugin Timestamps, created:"created_at", lastUpdated:"updated_at"

Mongoose.model 'Dict', DictSchema