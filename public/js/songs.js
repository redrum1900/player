// Generated by CoffeeScript 1.7.1
(function() {
  var ModalInstanceCtrl, songs;

  songs = angular.module('SongApp', ['ngGrid', 'ngRoute', 'ngTagsInput', 'ui.bootstrap']);

  songs.controller('SongCtrl', function($scope, $http, $modal, $q, $filter) {
    var listUri, updateStatusUri;
    listUri = '/song/list';
    updateStatusUri = '/song/update/status';
    configScopeForNgGrid($scope);
    $scope.search = function() {
      $scope.page = 1;
      $scope.list = null;
      return $scope.getList();
    };
    $scope.getList = function() {
      var tags;
      tags = '';
      if ($scope.s_tags) {
        tags = [];
        $scope.s_tags.forEach(function(tag) {
          return tags.push(tag.text);
        });
        tags = tags.join(',');
      }
      return $http.get(listUri, {
        params: {
          name: $scope.searchText,
          tags: tags,
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
      enableHighlighting: true,
      rowHeight: 40,
      columnDefs: [
        {
          field: "name",
          displayName: "名称",
          cellTemplate: textCellTemplate
        }, {
          field: "tags",
          displayName: "标签",
          cellTemplate: textCellTemplate
        }, {
          field: "id3",
          displayName: "歌曲信息",
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
    $scope.tags = [];
    getDict($http, 'SongTags', function(result) {
      if (result && result.list && result.list.length) {
        return result.list.forEach(function(tag) {
          console.log(tag);
          if (typeof tag === 'string') {
            return $scope.tags.push({
              text: tag
            });
          } else {
            return $scope.tags.push(tag);
          }
        });
      }
    });
    $scope.loadTags = function(query) {
      var deffered;
      deffered = $q.defer();
      deffered.resolve($filter('filter')($scope.tags, query));
      return deffered.promise;
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
          },
          tags: function() {
            return $scope.tags;
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

  ModalInstanceCtrl = function($scope, $timeout, $modalInstance, data, tags, http, $q, $filter) {
    $scope.data = data;
    $scope.buttonDisabled = false;
    $scope.tags = tags;
    $scope.label = '上传媒资';
    if (data._id) {
      $scope.update = true;
      $scope.title = '编辑媒资';
      $scope.cover = imgHost + $scope.data.cover + '?imageView2/1/w/200/h/200';
    } else {
      $scope.title = '新增媒资';
    }
    $scope.loadTags = function(query) {
      var deffered;
      deffered = $q.defer();
      deffered.resolve($filter('filter')($scope.tags, query));
      return deffered.promise;
    };
    $timeout(function() {
      var uploader, uploader2;
      uploader = Qiniu.uploader({
        runtimes: 'html5,flash,html4',
        browse_button: 'p1',
        uptoken_url: '/upload/token/mp3',
        unique_names: true,
        domain: imgHost,
        container: 'c1',
        max_file_size: '10mb',
        flash_swf_url: 'js/plupload/Moxie.swf',
        dragdrop: true,
        drop_element: 'c1',
        max_retries: 1,
        auto_start: true,
        init: {
          'BeforeUpload': function(up, file) {
            return $scope.buttonDisabled = true;
          },
          'FileUploaded': function(up, file, info) {
            data = angular.fromJson(info);
            console.log(data);
            return $timeout(function() {
              $scope.data.url = data.key;
              $scope.size = file.size;
              $scope.label = '上传成功';
              return $scope.buttonDisabled = false;
            }, 500);
          },
          'UploadProgress': function(up, file) {
            return $scope.label = file.percent + "%";
          },
          'Error': function(up, err, errTip) {
            $scope.msg = err;
            return $scope.buttonDisabled = false;
          }
        }
      });
      $scope.imgProgress = '上传封面';
      return uploader2 = Qiniu.uploader({
        runtimes: 'html5,flash,html4',
        browse_button: 'p2',
        uptoken_url: '/upload/token',
        unique_names: true,
        domain: imgHost,
        container: 'c2',
        max_file_size: '10mb',
        flash_swf_url: 'js/plupload/Moxie.swf',
        dragdrop: true,
        drop_element: 'c2',
        max_retries: 1,
        auto_start: true,
        init: {
          'BeforeUpload': function(up, file) {
            return $scope.buttonDisabled = true;
          },
          'FileUploaded': function(up, file, info) {
            data = angular.fromJson(info);
            console.log(data);
            return $timeout(function() {
              $scope.data.cover = data.key;
              $scope.cover = imgHost + $scope.data.cover + '?imageView2/1/w/200/h/200';
              $scope.buttonDisabled = false;
              return $scope.imgProgress = '上传封面';
            }, 500);
          },
          'UploadProgress': function(up, file) {
            return $scope.imgProgress = file.percent + "%";
          },
          'Error': function(up, err, errTip) {
            $scope.msg = err;
            return $scope.buttonDisabled = false;
          }
        }
      });
    }, 500);
    $scope.cancel = function() {
      $modalInstance.close();
    };
    $scope.ok = function() {
      var msg;
      if (!$scope.data.name) {
        msg = '媒资名称必填';
      } else if (!$scope.data.url) {
        msg = '媒资尚未上传';
      } else if (!$scope.data.cover) {
        msg = '媒资封面尚未添加';
      }
      if (msg) {
        $scope.msg = msg;
        return;
      } else {
        $scope.buttonDisabled = true;
        tags = [];
        if ($scope.data.tags) {
          $scope.data.tags.forEach(function(tag) {
            if (typeof tag === 'string') {
              return tags.push(tag);
            } else {
              return tags.push(tag.text);
            }
          });
        }
        $scope.data.tags = tags;
        if ($scope.update) {
          http.post('/song/update', $scope.data).success(function(result) {
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
          http.post('/song/add', $scope.data).success(function(result) {
            if (result.status) {
              return $modalInstance.close(result.results);
            } else {
              $scope.msg = result.error;
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

  angular.element(document).ready(function() {
    return angular.bootstrap(document.getElementById("songDiv"), ['SongApp']);
  });

}).call(this);

//# sourceMappingURL=songs.map
