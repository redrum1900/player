// Generated by CoffeeScript 1.7.1
(function() {
  var ModalInstanceCtrl, user_m;

  user_m = angular.module('UserMApp', ['ngGrid', 'ui.bootstrap']);

  user_m.controller('UserMCtrl', function($scope, $http, $modal) {
    var listUri, updateStatusUri;
    listUri = '/user/list';
    updateStatusUri = '/user/update/status';
    configScopeForNgGrid($scope);
    $scope.search = function() {
      $scope.page = 1;
      $scope.list = null;
      return $scope.getList();
    };
    $scope.getList = function() {
      return $http.get(listUri, {
        params: {
          username: $scope.searchText,
          page: $scope.page,
          perPage: 20
        }
      }).success(function(result) {
        if (result.status) {
          if (!$scope.list) {
            return $scope.list = result.results;
          } else if (result.results && result.results.length) {
            return result.results.forEach(function(item) {
              return $scope.list.push(item);
            });
          } else {
            return showAlert('没有更多的数据了');
          }
        } else {
          return showAlert(result.error);
        }
      });
    };
    $scope.getList();
    $scope.updateStatus = function(data) {
      $scope.updating = true;
      data.disabled = !data.disabled;
      return $http.post(updateStatusUri, {
        _id: data._id,
        disabled: data.disabled
      }).success(function(result) {
        if (!result.status) {
          showAlert(result.error);
        }
        return $scope.updating = false;
      });
    };
    $scope.page = 1;
    $scope.$on('ngGridEventScroll', function() {
      $scope.page++;
      return $scope.getList();
    });
    $scope.dataGrid = {
      data: 'list',
      multiSelect: false,
      enableRowSelection: false,
      enableSorting: false,
      rowHeight: 40,
      columnDefs: [
        {
          field: "udid",
          displayName: "设备号",
          cellTemplate: textCellTemplate
        }, {
          field: "username",
          displayName: "用户名",
          cellTemplate: textCellTemplate
        }, {
          field: "mobile",
          displayName: "手机号",
          width: 115,
          cellTemplate: textCellTemplate
        }, {
          field: "email",
          displayName: "邮箱",
          cellTemplate: textCellTemplate
        }, {
          field: "creator.username",
          width: 88,
          displayName: "创建者",
          cellTemplate: textCellTemplate
        }, {
          field: "created_at",
          width: 100,
          displayName: "创建时间",
          cellTemplate: dateCellTemplate
        }, {
          field: "updator.username",
          width: 88,
          displayName: "更新者",
          cellTemplate: textCellTemplate
        }, {
          field: "updated_at",
          width: 100,
          displayName: "更新时间",
          cellTemplate: dateCellTemplate
        }, {
          field: "handler",
          displayName: "操作",
          width: 100,
          cellTemplate: '<div class="row" ng-style="{height: rowHeight}"> <div class="col-md-8 col-md-offset-2" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px"> <a class="btn btn-primary btn-xs col-md-5" ng-click="edit(row.entity)">编辑</a> <a class="btn btn-xs col-md-5 col-md-offset-2" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'
        }
      ]
    };
    $scope.edit = function(data) {
      $scope.data = data;
      return $scope.open();
    };
    $scope.add = function() {
      $scope.data = {};
      $scope.open();
    };
    $scope.open = function() {
      var modalInstance;
      modalInstance = $modal.open({
        templateUrl: 'modal.html',
        controller: ModalInstanceCtrl,
        backdrop: 'static',
        resolve: {
          data: function() {
            return $scope.data;
          },
          http: function() {
            return $http;
          }
        }
      });
      modalInstance.result.then((function(data) {
        if (!$scope.list) {
          $scope.list = [];
        }
        if (data === 'refresh') {
          $scope.list = null;
          $scope.page = 1;
          $scope.getList();
        } else if (data) {
          $scope.list.unshift(data);
        }
      }), function() {});
    };
  });

  angular.bootstrap(document.getElementById("userMDiv"), ['UserMApp']);

  ModalInstanceCtrl = function($scope, $modalInstance, data, http) {
    var getOptions;
    data.tempPros = {};
    if (data.pros) {
      data.pros.forEach(function(pro) {
        return data.tempPros[pro.key] = pro.value;
      });
    }
    getOptions = function(key, callback, subKey, valuePro) {
      getDict(http, key, function(result) {
        if (subKey) {
          if (result && valuePro) {
            $scope[subKey][key] = result[valuePro];
          } else {
            $scope[subKey][key] = result;
          }
          console.log($scope[subKey]);
        } else {
          $scope[key] = result;
        }
        if (result && callback) {
          return callback(result);
        }
      });
    };
    getOptions('UserFrom');
    $scope.Pros = {};
    getOptions('UserExtraPro', function(result) {
      var pro, _i, _len, _ref, _results;
      if (result && result.list && result.list.length) {
        _ref = result.list;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pro = _ref[_i];
          _results.push((function(pro) {
            return getOptions(pro, null, 'Pros', 'list');
          })(pro));
        }
        return _results;
      }
    });
    $scope.data = data;
    $scope.buttonDisabled = false;
    if (data._id) {
      $scope.update = true;
      $scope.title = '编辑用户';
    } else {
      $scope.title = '新增用户';
    }
    configDateForScope($scope);
    $scope.maxDate = new Date();
    $scope.open = function($event) {
      return $scope.opened = true;
    };
    $scope.cancel = function() {
      $modalInstance.close();
    };
    $scope.select = function(value) {
      $scope.selectedType = value;
    };
    $scope.ok = function() {
      var k, msg;
      for (k in data.tempPros) {
        if (!data.pros) {
          data.pros = [];
        }
        data.pros.push({
          key: k,
          value: data.tempPros[k]
        });
      }
      console.log(data);
      if (!($scope.data.username || $scope.data.mobile)) {
        msg = '用户名和手机号必填一项';
      } else if (!$scope.data.come_from) {
        msg = '请选择用户来源';
      }
      if (msg) {
        $scope.msg = msg;
        return;
      } else {
        delete data['tempPros'];
        $scope.buttonDisabled = true;
        if ($scope.update) {
          http.post('/user/update', $scope.data).success(function(result) {
            if (result.status) {
              return $modalInstance.close('refresh');
            } else {
              $scope.msg = result.results;
              return $scope.buttonDisabled = false;
            }
          }).error(function(error) {
            $scope.msg = '出错了，请稍后再试';
            return $scope.buttonDisabled = false;
          });
        } else {
          http.post('/user/add', $scope.data).success(function(result) {
            if (result.status) {
              return $modalInstance.close(result.results);
            } else {
              $scope.msg = result.results;
              return $scope.buttonDisabled = false;
            }
          }).error(function(error) {
            $scope.msg = '出错了，请稍后再试';
            return $scope.buttonDisabled = false;
          });
        }
      }
    };
  };

}).call(this);

//# sourceMappingURL=user_m.map
