// Generated by CoffeeScript 1.7.1
(function() {
  var setting;

  setting = angular.module('SettingApp', ['ngTagsInput', 'ui.bootstrap']);

  setting.controller('ProgressDemoCtrl', function($scope) {});

  setting.controller('SettingCtrl', function($scope, $http) {
    var updateResult;
    $scope.getTags = function(key, callback, subKey, valuePro) {
      getDict($http, key, function(result) {
        if (subKey) {
          if (result && valuePro) {
            $scope[subKey][key] = result[valuePro];
          } else {
            $scope[subKey][key] = result;
          }
        } else {
          $scope[key] = result;
        }
        if (result && callback) {
          return callback(result);
        }
      });
    };
    $scope.updateTags = function(key, list, callback, isPro) {
      var arr, data;
      if (isPro) {
        data = {
          key: key,
          list: list
        };
      } else {
        data = list;
      }
      data.key = key;
      arr = [];
      data.list.forEach(function(text) {
        return arr.push(text.text);
      });
      data.list = arr;
      $scope.handling = true;
      console.log(data);
      $http.post('/dict/update/list', data).success(function(result) {
        $scope.handling = false;
        if (result.status) {
          return callback(true);
        } else {
          return showAlert(result.error);
        }
      });
    };
    updateResult = function(result) {
      if (!result.status) {
        return showAlert(result.error);
      }
    };
    $scope.tagAdded = function(key) {
      return $scope.updateTags(key, $scope[key], updateResult);
    };
    $scope.tagRemoved = function(key) {
      return $scope.updateTags(key, $scope[key], updateResult);
    };
    $scope.getTags('QUserPros');
    $scope.getTags('UserFrom');
    $scope.Pros = {};
    $scope.proRemoved = function(key) {
      return $scope.updateTags(key, $scope.Pros[key], updateResult, true);
    };
    $scope.proAdded = function(key) {
      return $scope.updateTags(key, $scope.Pros[key], updateResult, true);
    };
    $scope.getTags('UserExtraPro', function(result) {
      var pro, _i, _len, _ref, _results;
      if (result && result.list && result.list.length) {
        _ref = result.list;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pro = _ref[_i];
          _results.push((function(pro) {
            return $scope.getTags(pro, null, 'Pros', 'list');
          })(pro));
        }
        return _results;
      }
    });
    return $scope.getTags('ResearchTags');
  });

  angular.bootstrap(document.getElementById("settingDiv"), ['SettingApp']);

}).call(this);

//# sourceMappingURL=setting.map
