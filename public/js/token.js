var GetToken = function($http, callback) {
    if($.cookie('token')){
        callback($.cookie('token'));
    }else{
        $http.get('/upload/token').success(function(result){
            if(result.status){
                var date = new Date();
                var minutes = 60;
                date.setTime(date.getTime() + (minutes * 60 * 1000));
                $.cookie('token', result.results, {expires:date})
                callback(result.results);
            }else{
                callback(false);
            }
        })
    }
};