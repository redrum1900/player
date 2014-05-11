'use strict';
var imgHost = 'http://lenovour.qiniudn.com/';
var uploadHost = 'http://up.qiniu.com/';

var getDict = function(http, key, callback){
    http.get('/dict/get', {params: {key: key}}).success(function (result) {
        if (result.status)
            callback(result.results);
        else
            showAlert(result.error);
    });
}

/**
 * 获取字典并自动赋值
 * @param scope
 * @param http
 * @param key
 * @param callback
 * @param subDictKey
 * @param valuePro
 */
var getDicts = function(scope, http, key, callback, subDictKey, valuePro){
    getDict(http, key, function (result) {
        if(!subDictKey){
            scope[key] = result;
        }else{
            if(!scope[subDictKey])
                scope[subDictKey] = {};
            if(valuePro && result){
                scope[subDictKey][key] = result[valuePro];
                console.log(result, valuePro, scope[subDictKey]);
            }else{
                scope[subDictKey][key] =  result;
            }
        }
        if(callback)
            callback(result);
    });
}

var enableNGEnter = function(app){
    app.directive('ngEnter', function () {
        return function (scope, element, attrs) {
            element.bind("keydown keypress", function (event) {
                if(event.which === 13) {
                    scope.$apply(function (){
                        scope.$eval(attrs.ngEnter);
                    });
                    event.preventDefault();
                }
            });
        };
    });
}

var configDateForScope = function($scope){
    $scope.format = 'yyyy/MM/dd';
    $scope.dateOptions = {
        'year-format': 'yyyy',
        'starting-day': 1
    };
}

var enableNGBindModel = function(app){

    app.directive('ngBindModel', function() {
        return {
            link: function($scope, elem, attr, ctrl) {
                console.debug($scope);
                //var textField = $('input', elem).attr('ng-model', 'myDirectiveVar');
                // $compile(textField)($scope.$parent);
            }
        }
    });

    app.directive("cleanMe", function() {
        return {
            link: function(scope, element, attributes) {
                return scope.$watch(attributes.ngModel, function(value) {
                    console.log(value);
                });
            }
        };
    });

//    app.directive('ngBindModel',function(){
//        return{
//            compile:function(tEl,tAtr){
//                console.log('test')
////                $compile(tEl[0])(scope)
////                tEl[0].removeAttribute('ng-bind-model')
////                return function(scope){
//////                    tEl[0].setAttribute('ng-model',scope.$eval(tAtr.ngBindModel))
//////                    $compile(tEl[0])(scope)
////                    console.info('new compiled element:',tEl[0])
////                }
//            }
//        }
//    })
}