var navScope;
var navTimeOut;

var nav = angular.module('nav', []);

function NavController($scope, $timeout){
	$scope.navs = [
		{href:'/console', label:'控制台'},
		{href:'/research', label:'调查研究'},
		{href:'/question', label:'研究题库'},
		{href:'/user_management', label:'用户管理'},
		{href:'/feedback', label:'日志研究'},
        {href:'/info', label:'资讯管理'},
		{href:'/setting', label:'系统设置'}
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