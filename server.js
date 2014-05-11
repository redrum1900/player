var http = require('http');
var port = 18080;

var log4js = require('log4js');
log4js.loadAppender('baev3-log');
var options = {
    'user': '9RGMgDe0USUb1ODDnQgRBhN2',
    'passwd': 'xt6e5Qrx93m1ebGHUpxHh7qB4CjnlKti'
}

http.createServer(function(req, res) {

	log4js.addAppender(log4js.appenders['baev3-log'](options));

	var logger = log4js.getLogger('node-log-sdk');
	logger.trace('baev3-log trace log112');
	logger.debug('baev3-log Debug log1');
	logger.info('baev3-log Info log1');
	logger.warn('baev3-log Warn log1');
	logger.error('baev3-log Error log1');
	logger.fatal('baev3-log Fatal log1');

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write('<h1>Node.js</h1>');
    res.end('<p>Hello World</p>');
}).listen(port);
