// Generated by CoffeeScript 1.7.1
(function() {
  var cs;

  cs = angular.module('ConsoleApp', ['nvd3ChartDirectives']);

  cs.controller('ConsoleCtrl', function($scope, $http) {
    $scope.data = [
      {
        "key": "提交报告数",
        "values": [[1, 0], [2, 10], [3, 120], [4, 130], [5, 140], [6, 1000], [7, 160], [8, 170], [9, 500], [12, 1500], [13, 3000]]
      }
    ];
    return $http.get('/sms/left').success(function(result) {
      console.log(result);
      return $scope.smsLeft = result.result;
    });
  });

  angular.element(document).ready(function() {
    return angular.bootstrap(document.getElementById("consoleDiv"), ['ConsoleApp']);
  });

}).call(this);

//# sourceMappingURL=console.map
