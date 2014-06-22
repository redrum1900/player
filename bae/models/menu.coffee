Mongoose = require 'mongoose'
Schema = Mongoose.Schema

MenuSchema = new Schema
  name:type:String,required:true,index:unique:true
  list:[
    name:String
    begin:String
    end:String
    loop:Boolean
    songs:[
      song:type:Schema.Types.ObjectId,ref:"Song"
      allow_circle:type:Boolean,default:false
    ]
    index:type:Number
  ]
  dm_list:[
    dm:type:Schema.Types.ObjectId,ref:"DM"
    repeat:Number #重复次数
    playTime:String #播放时间
    interval:Number #间隔时间
    day:String #星期
  ]
  type:type:Number,index:true
  quality:type:Number,default:64
  clients:type:[Schema.Types.ObjectId,ref:"Client"],index:true
  begin_date:Date
  end_date:Date
  tags:type:[String],index:true
  disabled:type:Boolean,default:false
  creator:type:Schema.Types.ObjectId,ref:"Manager"
  updator:type:Schema.Types.ObjectId,ref:"Manager"

Timestamps = require('mongoose-times')
MenuSchema.plugin Timestamps, created:"created_at", lastUpdated:"updated_at"

Mongoose.model 'Menu', MenuSchema