qiniu = require 'qiniu'

qiniu.conf.ACCESS_KEY = 'xyGeW-ThOyxd7OIkwVKoD4tHZmX0K0cYJ6g1kq4J';
qiniu.conf.SECRET_KEY = 'bJSwo1--7pa-HD3g7fFHaI6e_TOYP1NCk3Z7XM7G';

client = new qiniu.rs.Client()

client.stat 'yfcdn', 'temp/1.mp3', (err, result)->
  console.log err, result
