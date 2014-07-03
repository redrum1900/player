models = require '../models'
Log = models.Log
auth = require '../lib/auth'
Error = require '../lib/error'
Client = models.Client
moment = require 'moment'

module.exports = (app)->
#data = req.query
#limit = parseInt data.perPage
#skip =  limit*(parseInt(data.page)-1)
#match = 'report.qid':data.qid
#if data.marked == 'true'
#  match['report.remark']=$exists:true
#Report.aggregate()
#.unwind('report')
#.match(match)
#.project(
#  value:'$report.value'
#  remark:'$report.remark'
#  user:'$user'
#  created_at:'$created_at'
#  type:'$report.type'
#)
#.sort('created_at':-1)
#.skip(skip)
#.limit(limit)
#.exec (err, result)->
#  if err
#    Error err, res
#  else
#    res.json status:true, result:result
  app.get '/now', (req, res)->
    res.send new Date().toString()

  app.get '/logs',(req, res)->
    data = req.query
    query = {}
    data.perPage = 100 unless data.perPage
    data.page = 1 unless data.page
    Log.aggregate()
    .match(query)
    .project(
      username:'$client'
      c:'$count'
    ).group(
      _id:"$username"
      count:$sum:'$c'
    ).sort(count:-1)
    .skip(data.perPage*(data.page-1))
    .limit(data.perPage)
    .exec (err, result)->
      if err
        Error err, res
      else
        ids = []
        count = {}
        result.forEach (log)->
          ids.push log._id
          count[log._id] = log.count
        Client.find '_id':$in:ids, 'username', (err, result)->
          arr = []
          num = 1000;
          result.forEach (u)->
            arr.push username:u.username, count:count[u._id], dm:Math.round(num*Math.random()), received:Math.round(num*Math.random()), confirmed:Math.round(num*Math.random())
          arr.sort (a,b)->
            return -a.count + b.count
          res.json status:true, results:arr
#    Log.find(query)
#    .populate('client', 'username')
#    .limit(data.perPage)
#    .skip(data.perPage(data.page-1))

  app.get '/realtime', auth.isAuthenticated(), (req, res)->
    data = req.query
    Client.find data, '_id username geo', (err, clients)->
      if err
        Error err, res
      else
        ids = []
        clients.forEach (c)->
          ids.push c._id
        query =
          client:$in:ids
          created_at:moment().format("YYYY-MM-DD")
        Log.find query, 'client updated_at', (err, result)->
          if err
            Error err, res
          else
            console.log result
            arr = []
            o = {}
            if result
              result.forEach (r)->
                o[r.client] = r.updated_at
            console.log o
            clients.forEach (c)->
              result = username:c.username,geo:c.geo
              result.updated_at = o[c._id]
              arr.push result

            res.json status:true, result:arr