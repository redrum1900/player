// Generated by CoffeeScript 1.7.1
(function() {
  var Mongoose, Schema, SongSchema, Timestamps;

  Mongoose = require('mongoose');

  Schema = Mongoose.Schema;

  SongSchema = new Schema({
    name: {
      type: String,
      index: true,
      required: true
    },
    cover: String,
    url: String,
    tags: {
      type: [String],
      index: true
    },
    id3: Schema.Types.Mixed,
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

  SongSchema.plugin(Timestamps, {
    created: "created_at",
    lastUpdated: "updated_at"
  });

  Mongoose.model('Song', SongSchema);

}).call(this);

//# sourceMappingURL=song.map
