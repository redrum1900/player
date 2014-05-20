var navScope;
var navTimeOut;
var navModal;

var nav = angular.module('nav', ['ui.bootstrap']);

function NavController($scope, $timeout, $modal){
	$scope.navs = [
		{href:'/console', label:'控制台'},
		{href:'/songs', label:'媒资管理'},
        {href:'/menu', label:'歌单推送'},
		{href:'/clients', label:'客户管理'},
		{href:'/feedback', label:'客户反馈'},
		{href:'/setting', label:'系统设置'},
        {href:'/log', label:'操作日志'}
	];

    navScope = $scope;
    navTimeOut = $timeout;
    navModal = $modal;

	angular.forEach($scope.navs, function(nav){
		if(nav.href == window.location.pathname){
			nav.active = 'active';
		}
	});
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