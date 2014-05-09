auth = require '../lib/auth'
Dict = require('../models').Dict
Error = require '../lib/error'
Joi = require 'joi'
validator = require '../lib/validator'

DictSchema = key:Joi.string().required()


module.exports = (app) ->
  app.get '/dict/get', auth.isAuthenticated(), (req, res) ->
    data = req.query
    err = validator.validate(data, DictSchema, {});
    if err
      return res.json status:false,error:err
    Dict.findOne
      key:data.key
      'value list'
      (err, result) ->
        console.log err, result
        if err
          Error err, res
        else
          if result
            arr = []
            result.list.forEach (r) ->
              if typeof r == 'string'
                arr.push(r)
            result.list = arr
          res.json status:true, results:result
    return

  app.post '/dict/update/list', auth.isAuthenticated(), (req, res) ->
    data = req.body
    delete data['_id']
    Dict.findOneAndUpdate
      key: data.key
      data
      upsert: true
      (err, result) ->
        if err
          Error err, res
        else
          res.json status: true
    return

  return