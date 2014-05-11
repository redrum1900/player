var navScope;
var navTimeOut;

var nav = angular.module('nav', []);

function NavController($scope, $timeout){
	$scope.navs = [
		{href:'/console', label:'控制台'},
		{href:'/songs', label:'曲库管理'},
		{href:'/clients', label:'客户管理'},
		{href:'/feedback', label:'客户反馈'},
		{href:'/setting', label:'系统设置'},
        {href:'/log', label:'操作日志'}
	];

    navScope = $scope;
    navTimeOut = $timeout;

	angular.forEach($scope.navs, function(nav){
		if(nav.href == window.location.pathname){
			nav.active = 'active';
		}
	});
}

var showAlert = function(message){
    navTimeOut(function () {
        navScope.message = message;
        navTimeOut(function () {
            navScope.message = '';
        }, 3000);
    }, 100);
}