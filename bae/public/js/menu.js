// Generated by CoffeeScript 1.7.1
(function() {
  var ClientsModalInstanceCtrl, ModalInstanceCtrl, menu;

  menu = angular.module('MenuApp', ['ngGrid', 'ngRoute', 'ngTagsInput', 'ui.bootstrap']);

  menu.controller('MenuCtrl', function($scope, $http, $modal, $q, $filter) {
    var getSongs, listUri, updateStatus, updateStatusUri, validateTime;
    $scope.module = 'templates/html/menu/home.html';
    listUri = '/menu/list';
    updateStatusUri = '/menu/update/status';
    configScopeForNgGrid($scope);
    configDateForScope($scope);
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
          type: 1,
          name: $scope.menuName,
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
      if (!data.disabled) {
        return confirm(2, '歌单状态更新', '是否确认禁用该歌单，一旦禁用后客户将不能再不会再使用该歌单', function(value) {
          if (value) {
            return updateStatus(data);
          }
        });
      } else {
        return updateStatus(data);
      }
    };
    updateStatus = function(data) {
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
      if ($scope.module === 'templates/html/menu/home.html') {
        $scope.page++;
        return $scope.getList();
      }
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
          field: "clients.length",
          displayName: "使用客户",
          cellTemplate: textCellTemplate
        }, {
          field: "begin_date",
          displayName: "开始日期",
          cellTemplate: dateCellTemplate
        }, {
          field: "end_date",
          displayName: "结束日期",
          cellTemplate: dateCellTemplate
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
          field: "handler",
          displayName: "操作",
          width: 150,
          cellTemplate: '<div class="row" ng-style="{height: rowHeight}"> <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px"> <a class="btn btn-info btn-xs" ng-click="clients(row.entity)">客户</a> <a class="btn btn-primary btn-xs" ng-click="edit(row.entity)">编辑</a> <a class="btn btn-xs" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'
        }
      ]
    };
    $scope.songGrid = {
      data: 'time.songs',
      multiSelect: false,
      enableRowSelection: false,
      enableSorting: false,
      enableHighlighting: true,
      rowHeight: 40,
      columnDefs: [
        {
          field: "song.name",
          displayName: "名称",
          cellTemplate: textCellTemplate
        }, {
          field: "time",
          displayName: "播放时间",
          cellTemplate: textCellTemplate
        }, {
          field: "song.duration",
          displayName: "时长",
          cellTemplate: durationTemplate
        }, {
          field: "allow_circle",
          displayName: "是否允许随机播放",
          cellTemplate: textCellTemplate
        }, {
          field: "index",
          displayName: "排序",
          width: 55,
          cellTemplate: '<div class="row" ng-style="{height: rowHeight}"> <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px"> <input style="width: 40px;margin-right: 8px" tooltip-append-to-body="true" ng-model="row.entity.index" tooltip="排序，值越小越靠前"> </div></div>'
        }, {
          field: "handler",
          displayName: "操作",
          width: 120,
          cellTemplate: '<div class="row" ng-style="{height: rowHeight}"> <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px"> <input type="checkbox" style="margin-top: 7px; margin-right: 8px" ng-checked="row.entity.allow_circle" tooltip="允许随机循环" tooltip-append-to-body="true" ng-model="row.entity.allow_circle"> <a class="btn btn-warning btn-xs" ng-click="removeSong(row.entity)">移除</a> </div></div>'
        }
      ]
    };
    $scope.removeSong = function(song) {
      var arr;
      arr = $scope.time.songs;
      return arr.splice(arr.indexOf(song), 1);
    };
    $scope.edit = function(data) {
      $scope.data = data;
      $scope.time = data.list[0];
      $scope.module = 'templates/html/menu/edit.html';
      return $scope.refreshSongList();
    };
    $scope.add = function() {
      var time;
      time = {
        name: '默认时段',
        active: true,
        songs: []
      };
      $scope.data = {
        list: [time]
      };
      $scope.time = time;
      return $scope.module = 'templates/html/menu/edit.html';
    };
    $scope.changeTime = function(time) {
      $scope.time = time;
      console.log(time);
      return $scope.refreshSongList();
    };
    $scope.back = function() {
      $scope.module = 'templates/html/menu/home.html';
      $scope.list = null;
      return $scope.getList();
    };
    $scope.addTime = function() {
      var time;
      time = {
        name: '新增时段',
        songs: []
      };
      return $scope.data.list.push(time);
    };
    $scope["export"] = function() {
      var data;
      data = $scope.data;
      window.open('/menu/report/' + data._id + '/' + data.name + '.xlsx', '_blank');
    };
    validateTime = function(time) {
      var arr, h, m, wrong;
      if (!time) {
        wrong = true;
      } else {
        wrong = false;
        if (time.indexOf(':') === -1) {
          wrong = true;
        } else {
          arr = time.split(':');
          if (arr.length !== 2) {
            wrong = true;
          } else {
            h = parseInt(arr[0]);
            m = parseInt(arr[1]);
            time = moment({
              hour: h,
              minute: m
            });
            if (!time.isValid()) {
              wrong = true;
            }
          }
        }
      }
      if (wrong) {
        confirm(1, '时段开始或结束时间格式不对', '注意冒号格式，应该是 8:00或18:00 这样的');
        return false;
      } else {
        return true;
      }
    };
    $scope.addSong = function() {
      if (validateTime($scope.time.begin)) {
        return $scope.openAddSong();
      }
    };
    $scope.tags = [];
    getDict($http, 'MenuTags', function(result) {
      if (result && result.list && result.list.length) {
        return result.list.forEach(function(tag) {
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
    $scope.refreshSongList = function() {
      var begin, h, i, m, song, songs, time;
      songs = angular.copy($scope.time.songs);
      $scope.time.songs = null;
      begin = $scope.time.begin;
      if (!begin) {
        return;
      }
      i = 0;
      h = begin.split(':')[0];
      m = begin.split(':')[1];
      time = moment({
        hour: parseInt(h),
        minute: parseInt(m)
      });
      songs.sort(function(a, b) {
        return a.index - b.index;
      });
      while (i < songs.length) {
        song = songs[i];
        song.index = i;
        song.time = time.format('HH:mm:ss');
        if (song.song.duration) {
          time.add('s', song.song.duration);
        }
        i++;
      }
      time.add('m', 1);
      $scope.time.songs = songs;
      if (!$scope.time.loop) {
        return $scope.time.end = time.format('HH:mm');
      }
    };
    $scope.saveMenu = function() {
      var list, tags, wrong;
      menu = angular.copy($scope.data);
      if (!menu.name) {
        wrong = '歌单名称不能为空';
      }
      if (menu.quality) {
        if (parseInt(menu.quality) !== 64 && parseInt(menu.quality) !== 192) {
          wrong = '歌曲质量目前仅支持64和192两种';
        }
      }
      if (wrong) {
        return confirm(1, '保存失败', wrong);
      } else {
        list = menu.list;
        list.forEach(function(list) {
          var songs;
          songs = list.songs;
          if (songs) {
            return songs.forEach(function(s) {
              return s.song = s.song._id;
            });
          }
        });
        tags = [];
        if (menu.tags) {
          menu.tags.forEach(function(tag) {
            if (typeof tag === 'string') {
              return tags.push(tag);
            } else {
              return tags.push(tag.text);
            }
          });
        }
        menu.tags = tags;
        menu.type = 1;
        menu.quality = parseInt(menu.quality);
        if (menu.quality !== 192) {
          menu.quality = 64;
        }
        $scope.handling = true;
        console.log(menu);
        if (!menu._id) {
          return $http.post('/menu/add', menu).success(function(result) {
            if (!result.status) {
              showAlert(result.error);
            }
            $scope.data = result.results;
            $scope.handling = false;
            return confirm(2, '保存成功', '继续编辑或返回歌单列表', function(value) {
              if (!value) {
                return $scope.back();
              }
            }, '继续编辑', '返回列表');
          });
        } else {
          return $http.post('/menu/update', menu).success(function(result) {
            $scope.handling = false;
            if (!result.status) {
              showAlert(result.error);
            }
            return confirm(2, '保存成功', '继续编辑或返回歌单列表', function(value) {
              if (!value) {
                return $scope.back();
              }
            }, '继续编辑', '返回列表');
          });
        }
      }
    };
    $scope.clients = function(menu) {
      var modalInstance;
      modalInstance = $modal.open({
        templateUrl: 'clients.html',
        controller: ClientsModalInstanceCtrl,
        backdrop: 'static',
        resolve: {
          menu: function() {
            return menu;
          }
        }
      });
      return modalInstance.result.then((function(clients) {
        if (clients) {
          return $http.post('/menu/update', {
            _id: menu._id,
            clients: clients
          }).success(function(result) {
            if (!result.status) {
              showAlert(result.error);
            }
            return $scope.search();
          });
        }
      }), function() {});
    };
    getSongs = function() {
      var allsongs, data;
      allsongs = [];
      data = $scope.data;
      if (data.list && data.list.length) {
        data.list.forEach(function(list) {
          if (list.songs && list.songs.length) {
            return list.songs.forEach(function(song) {
              return allsongs.push(song.song._id);
            });
          }
        });
      }
      return allsongs;
    };
    return $scope.openAddSong = function() {
      var modalInstance;
      modalInstance = $modal.open({
        templateUrl: 'modal.html',
        controller: ModalInstanceCtrl,
        backdrop: 'static',
        resolve: {
          all: getSongs,
          songs: function() {
            var arr;
            arr = [];
            console.log($scope.time);
            if ($scope.time.songs) {
              $scope.time.songs.forEach(function(s) {
                if (s.song.duration) {
                  return arr.push(s.song);
                }
              });
            }
            return arr;
          }
        }
      });
      return modalInstance.result.then((function(data) {
        var allsongs, time;
        if (data) {
          time = $scope.time;
          if (!time.songs) {
            time.songs = [];
          }
          allsongs = getSongs();
          data.forEach(function(s) {
            var has;
            has = false;
            if (allsongs.indexOf(s._id) !== -1) {
              has = true;
            }
            if (!has) {
              return time.songs.push({
                song: s
              });
            }
          });
          $scope.refreshSongList();
        }
      }), function() {});
    };
  });

  ClientsModalInstanceCtrl = function($scope, $http, $timeout, $modalInstance, $q, $filter, menu) {
    var choosed, choosedLabel, choosedStyle, listUri, refreshStatus;
    listUri = '/user/list';
    configScopeForNgGrid($scope);
    menu = angular.copy(menu);
    $scope.clients = menu.clients;
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
          username: $scope.searchText,
          tags: tags,
          page: $scope.page,
          perPage: 20
        }
      }).success(function(result) {
        if (result.status) {
          if (!$scope.list) {
            $scope.list = result.results;
            return refreshStatus();
          } else if (result.results && result.results.length) {
            result.results.forEach(function(item) {
              return $scope.list.push(item);
            });
            return refreshStatus();
          } else {
            return showAlert('没有更多的数据了');
          }
        } else {
          return showAlert(result.error);
        }
      });
    };
    refreshStatus = function() {
      return $scope.list.forEach(function(item) {
        item.style = choosedStyle(item);
        return item.label = choosedLabel(item);
      });
    };
    $scope.getList();
    $scope.tags = [];
    getDict($http, 'ClientTags', function(result) {
      if (result && result.list && result.list.length) {
        return result.list.forEach(function(tag) {
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
    $scope.page = 1;
    $scope.$on('ngGridEventScroll', function() {
      $scope.page++;
      return $scope.getList();
    });
    choosed = function(data) {
      var has;
      has = false;
      $scope.clients.forEach(function(c) {
        if (c === data._id) {
          return has = true;
        }
      });
      return has;
    };
    choosedStyle = function(data) {
      if (choosed(data)) {
        return 'btn-warning';
      } else {
        return 'btn-success';
      }
    };
    choosedLabel = function(data) {
      if (choosed(data)) {
        return '取消';
      } else {
        return '选中';
      }
    };
    $scope.handle = function(data) {
      var i;
      if (choosed(data)) {
        i = 0;
        while (i < $scope.clients.length) {
          if ($scope.clients[i] === data._id) {
            $scope.clients.splice(i, 1);
          }
          i++;
        }
      } else {
        if ($scope.clients.indexOf(data._id) === -1) {
          $scope.clients.push(data._id);
        }
      }
      return refreshStatus();
    };
    $scope.cancel = function() {
      $modalInstance.close();
    };
    $scope.ok = function() {
      $modalInstance.close($scope.clients);
    };
    return $scope.dataGrid = {
      data: 'list',
      multiSelect: false,
      enableRowSelection: false,
      enableSorting: false,
      enableHighlighting: true,
      rowHeight: 40,
      columnDefs: [
        {
          field: "username",
          displayName: "客户名称",
          cellTemplate: textCellTemplate
        }, {
          field: "parent.username",
          displayName: "总部",
          cellTemplate: textCellTemplate
        }, {
          field: "tags",
          displayName: "标签",
          cellTemplate: textCellTemplate
        }, {
          field: "handler",
          displayName: "操作",
          width: 100,
          cellTemplate: '<div class="row" ng-style="{height: rowHeight}"> <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px"> <a class="btn btn-xs" ng-class="row.entity.style" ng-click="handle(row.entity)" ng-disabled="updating">{{ row.entity.label }}</a></div></div>'
        }
      ]
    };
  };

  ModalInstanceCtrl = function($scope, $http, $timeout, $modalInstance, $q, $filter, songs, all) {
    var choosed, choosedLabel, choosedStyle, listUri, refreshStatus, updateStatusUri;
    listUri = '/song/list';
    updateStatusUri = '/song/update/status';
    configScopeForNgGrid($scope);
    $scope.title = '插入媒资';
    $scope.songs = angular.copy(songs);
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
            $scope.list = result.results;
            return refreshStatus();
          } else if (result.results && result.results.length) {
            result.results.forEach(function(item) {
              return $scope.list.push(item);
            });
            return refreshStatus();
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
    refreshStatus = function() {
      return $scope.list.forEach(function(item) {
        if (all) {
          if (all.indexOf(item._id) !== -1) {
            item.choosed = true;
          }
        }
        if (!item.choosed) {
          item.style = choosedStyle(item);
          return item.label = choosedLabel(item);
        }
      });
    };
    choosed = function(data) {
      var has;
      has = false;
      $scope.songs.forEach(function(c) {
        if (c._id === data._id) {
          return has = true;
        }
      });
      return has;
    };
    choosedStyle = function(data) {
      if (choosed(data)) {
        return 'btn-warning';
      } else {
        return 'btn-success';
      }
    };
    choosedLabel = function(data) {
      if (choosed(data)) {
        return '取消';
      } else {
        return '选中';
      }
    };
    $scope.handle = function(data) {
      var i;
      if (choosed(data)) {
        i = 0;
        while (i < $scope.songs.length) {
          if ($scope.songs[i]._id === data._id) {
            $scope.songs.splice(i, 1);
          }
          i++;
        }
      } else {
        $scope.songs.push(data);
      }
      return refreshStatus();
    };
    $scope["try"] = function(data) {
      window.open(imgHost + data.url + '?p/1/avthumb/mp3/ab/64k');
      return true;
    };
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
          field: "handler",
          displayName: "操作",
          width: 100,
          cellTemplate: '<div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px"> <a class="btn btn-default btn-xs" ng-click="try(row.entity)">试听</a> <a ng-if="!row.entity.choosed" class="btn btn-success btn-xs" ng-class="row.entity.style" ng-click="handle(row.entity)">{{ row.entity.label }}</a> </div></div>'
        }
      ]
    };
    $scope.tags = [];
    getDict($http, 'SongTags', function(result) {
      if (result && result.list && result.list.length) {
        return result.list.forEach(function(tag) {
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
    $scope.cancel = function() {
      $modalInstance.close();
    };
    return $scope.ok = function() {
      $modalInstance.close($scope.songs);
    };
  };

  angular.element(document).ready(function() {
    return angular.bootstrap(document.getElementById("menuDiv"), ['MenuApp']);
  });

}).call(this);

//# sourceMappingURL=menu.map
