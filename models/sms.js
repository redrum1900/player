var Mongoose = require('mongoose');
var Schema = Mongoose.Schema;

var SMS = new Schema({
    mobile:{type:String, index:true, required:true},
    content:{type:String, required:true},
    type:{type:String, index:true}, //
    user:Schema.ObjectId,
    creator:{type:Schema.ObjectId, ref:'Admin'}
})

var Timestamps = require('mongoose-times');
SMS.plugin(Timestamps, {created: "created_at", lastUpdated: "updated_at"});

SMS.statics = {
    list: function(options, callback){
        var perPage = options.perPage;
        var page = options.page;
        delete options.perPage;
        delete options.page;
        delete options.id;
        console.log('Get smses: ', options);
        this.find(options)
            .populate('creator', 'worker_id')
            .sort({'created_at': -1})
            .limit(perPage)
            .skip(perPage * (page - 1))
            .exec(callback);
    },

    types:{
        VERIFY_CODE:1,
        ORDER_INFO:2
    }
}

Mongoose.model('SMS', SMS);
