var Mongoose = require('mongoose');
var Schema = Mongoose.Schema;

var ApplySchema = new Schema({
    username: {required: true, type: 'String', index: {unique:true}},
    email:{type:'String', required:true, index:true},
    approved:{type:Boolean, default:false},
    handled:Boolean,
    manager:{type:Schema.ObjectId, ref:'Manager'}
});

var Timestamps = require('mongoose-times');
ApplySchema.plugin(Timestamps, {created: "created_at", lastUpdated: "updated_at"});

module.exports = Mongoose.model('Apply', ApplySchema);