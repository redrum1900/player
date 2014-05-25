// Generated by CoffeeScript 1.7.1
(function() {
  var DMSchema, Mongoose, Schema, Timestamps;

  Mongoose = require('mongoose');

  Schema = Mongoose.Schema;

  DMSchema = new Schema({
    name: {
      type: String,
      index: true,
      required: true
    },
    url: String,
    size: Number,
    duration: Number,
    tags: {
      type: [String],
      index: true
    },
    disabled: {
      type: Boolean,
      "default": false
    },
    creator: {
      type: Schema.Types.ObjectId,
      ref: "Manager"
    },
    updator: {
      type: Schema.Types.ObjectId,
      ref: "Manager"
    }
  });

  Timestamps = require('mongoose-times');

  DMSchema.plugin(Timestamps, {
    created: "created_at",
    lastUpdated: "updated_at"
  });

  Mongoose.model('DM', DMSchema);

}).call(this);

//# sourceMappingURL=dm.map
