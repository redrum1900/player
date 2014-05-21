var navScope;
var navTimeOut;

var nav = angular.module('nav', ['ui.bootstrap']);

function NavController($scope, $timeout, $modal){

    navModal = $modal;
    navScope = $scope;
    navTimeOut = $timeout;

    $scope.init = function (navs){
        $scope.navs = angular.fromJson(navs);
        angular.forEach($scope.navs, function(nav){
            if(nav.href == window.location.pathname){
                nav.active = 'active';
            }
        });
    }
}

var confirm = function(type, title, content,callback, ok, cancel){
    var template = type == 1 ? 'modal/confirm.html' : 'modal/choose.html';
    console.log(template);
    var modalInstance = navModal.open({
        templateUrl: template,
        controller: ModalInstanceCtrl,
        resolve: {
            title:function(){return title},
            content:function(){return content},
            ok:function(){return ok},
            cancel:function(){return cancel}
        }
    });

    modalInstance.result.then(function (value) {
        if(callback){
            callback(value);
        }
    }, function () {
        if(callback){
            callback(false);
        }
    });
}

var ModalInstanceCtrl = function ($scope, $modalInstance, title, content, ok, cancel) {
    $scope.okLabel = ok ? ok : '确认';
    $scope.title = title;
    $scope.content = content;
    $scope.cancelLabel = cancel ? cancel : '取消';

    $scope.ok = function (value) {
        $modalInstance.close(value);
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
};


var showAlert = function(message){
    navTimeOut(function () {
        navScope.message = message;
        navTimeOut(function () {
            navScope.message = '';
        }, 3000);
    }, 100);
}