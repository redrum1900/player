menu = angular.module 'MenuApp', ['ngGrid', 'ngRoute', 'ngTagsInput', 'ui.bootstrap']
menu.controller 'MenuCtrl', ($scope, $http, $modal, $q, $filter) ->

  $scope.module = 'templates/html/menu/home.html'

  listUri = '/menu/list'
  updateStatusUri = '/menu/update/status'
  configScopeForNgGrid $scope
  configDateForScope $scope

  $scope.search = ->
    $scope.page = 1
    $scope.list = null
    $scope.getList()

  $scope.getList = ->
    tags = ''
    if $scope.s_tags
      tags = []
      $scope.s_tags.forEach (tag)->
        tags.push tag.text
      tags = tags.join ','
    $http.get(listUri, params:name:$scope.menuName,tags:tags,page:$scope.page,perPage:20).success (result) ->
      if(result.status)
        if !$scope.list
          $scope.list = result.results;
        else if result.results and result.results.length
          result.results.forEach (item)->
            $scope.list.push item
        else
          showAlert '没有更多的数据了'
      else
        showAlert result.error

  $scope.getList()

  $scope.updateStatus = (data) ->
    $scope.updating = true
    data.disabled = !data.disabled
    $http.post(updateStatusUri,{_id:data._id, disabled:data.disabled}).success (result) ->
      showAlert result.error unless result.status
      $scope.updating = false

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getList()

  $scope.dataGrid =
    data:'list'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    enableHighlighting:true
    rowHeight:40
    columnDefs:[
      {field: "name", displayName:"名称", cellTemplate: textCellTemplate}
      {field: "tags", displayName:"标签", cellTemplate: textCellTemplate}
      {field: "clients.length", displayName:"使用客户", cellTemplate: textCellTemplate}
      {field: "begin_date", displayName:"开始日期", cellTemplate: dateCellTemplate}
      {field: "end_date", displayName:"结束日期", cellTemplate: dateCellTemplate}
      {field: "creator.username", width:88, displayName:"创建者", cellTemplate: textCellTemplate}
      {field: "created_at", width:100, displayName:"创建时间", cellTemplate: dateCellTemplate}
      {field: "updator.username", width:88, displayName:"更新者", cellTemplate: textCellTemplate}
      {field: "updated_at", width:100, displayName:"更新时间", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "操作", width:100, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
                  <div class="col-md-8 col-md-offset-2" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
                  <a class="btn btn-primary btn-xs col-md-5" ng-click="edit(row.entity)">编辑</a>
                  <a class="btn btn-xs col-md-5 col-md-offset-2" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'}
    ]

  $scope.songGrid =
    data:'time.songs'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    enableHighlighting:true
    rowHeight:40
    columnDefs:[
      {field: "song.name", displayName:"名称", cellTemplate: textCellTemplate}
      {field: "time", displayName:"播放时间", cellTemplate: textCellTemplate}
      {field: "song.duration", displayName:"时长（秒）", cellTemplate: textCellTemplate}
      {field: "allow_circle", displayName:"是否允许随机播放", cellTemplate: textCellTemplate}
      {field: "handler", displayName: "操作", width:180, cellTemplate: '
      <div class="row" ng-style="{height: rowHeight}">
      <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
        <input type="checkbox" style="margin-top: 7px; margin-right: 8px" ng-checked="row.entity.allow_circle" tooltip="允许随机循环" tooltip-append-to-body="true" ng-model="row.entity.allow_circle">
        <input style="width: 40px;margin-right: 8px" tooltip-append-to-body="true" ng-model="row.entity.index" tooltip="排序，值越小越靠前">
        <a class="btn btn-warning btn-xs" ng-click="removeSong(row.entity)">移除</a>
        </div></div>'}
    ]

  $scope.removeSong = (song)->
    arr = $scope.time.songs
    arr.splice arr.indexOf(song), 1

  $scope.edit = (data) ->
    $scope.data = data
    $scope.time = data.list[0]
    $scope.module = 'templates/html/menu/edit.html'
    $scope.refreshSongList()

  $scope.add = ->
    time = name:'默认时段', active:true
    $scope.data = {list:[time]}
    $scope.time = time
    $scope.module = 'templates/html/menu/edit.html'

  $scope.changeTime = (time)->
    $scope.time = time
    $scope.refreshSongList()

  $scope.back = ->
    $scope.module = 'templates/html/menu/home.html'
    $scope.list = null
    $scope.getList()

  $scope.addTime = ->
    time = name:'新增时段'
    $scope.data.list.push time

  validateTime = (time)->
    if !time
      wrong = true
    else
      wrong = false
      if time.indexOf(':') == -1
        wrong = true
      else
        arr = time.split(':')
        if arr.length != 2
          wrong = true
        else
          h = parseInt(arr[0])
          m = parseInt(arr[1])
          time = moment(hour:h,minute:m)
          console.log time, time.isValid()
          if !time.isValid()
            wrong = true
    if wrong
      confirm(1, '时段开始或结束时间格式不对', '注意冒号格式，应该是 8:00或18:00 这样的')
      return false
    else
      return true

  $scope.addSong = ->
    if validateTime($scope.time.begin) && validateTime($scope.time.end)
      $scope.open()

  $scope.tags = []
  getDict $http, 'MenuTags', (result) ->
    if result and result.list and result.list.length
      result.list.forEach (tag) ->
        console.log tag
        if typeof tag == 'string'
          $scope.tags.push text:tag
        else
          $scope.tags.push tag

  $scope.loadTags = (query) ->
    deffered = $q.defer()
    deffered.resolve $filter('filter') $scope.tags, query
    return deffered.promise

  $scope.refreshSongList = ->
    songs = $scope.time.songs
    i = 0
    begin = $scope.time.begin
    h = begin.split(':')[0]
    m = begin.split(':')[1]
    time = moment(hour:h,minute:m)
    songs.sort (a, b)->
      return a.index-b.index
    while i < songs.length
      song = songs[i]
      song.index = i
      song.time = time.format('HH:mm:ss')
      if song.song.duration
        time.add 's', song.song.duration
      i++

  $scope.saveMenu = ->
    $scope.handling = false
    menu = angular.copy $scope.data
    if !menu.name
      wrong = '歌单名称不能为空'
      return confirm(1, '保存失败', wrong)
    else
      console.log 'save menu', menu
      list = menu.list
      list.forEach (list)->
        songs = list.songs
        if songs
          console.log songs
          songs.forEach (s)->
            s.song = s.song._id
      console.log 'save menu', menu
      if !menu._id
        $http.post('/menu/add',menu).success (result) ->
          showAlert result.error unless result.status
          confirm(2, '保存成功', '继续编辑或返回歌单列表', (value)->
            if(!value)
              $scope.back()
          , '继续编辑', '返回列表')
      else
        $http.post('/menu/update',menu).success (result) ->
          showAlert result.error unless result.status
          confirm(2, '保存成功', '继续编辑或返回歌单列表', (value)->
            if(!value)
              $scope.back()
          , '继续编辑', '返回列表')

  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl:'modal.html'
      controller:ModalInstanceCtrl
      backdrop:'static'
    )
    modalInstance.result.then ((data) ->
      if data
        time = $scope.time
        time.songs = [] unless time.songs
        data.forEach (s)->
          has = false
          time.songs.forEach (s2)->
            if s._id == s2._id
              has = true
          time.songs.push(song:s) unless has
        $scope.refreshSongList()
      return
    ), ->
      return

ModalInstanceCtrl = ($scope, $http, $timeout, $modalInstance,$q, $filter) ->

  listUri = '/song/list'
  updateStatusUri = '/song/update/status'
  configScopeForNgGrid $scope

  $scope.title = '插入媒资'

  $scope.search = ->
    $scope.page = 1
    $scope.list = null
    $scope.getList()

  $scope.getList = ->
    tags = ''
    if $scope.s_tags
      tags = []
      $scope.s_tags.forEach (tag)->
        tags.push tag.text
      tags = tags.join ','
    $http.get(listUri, params:name:$scope.searchText,tags:tags,page:$scope.page,perPage:20).success (result) ->
      if(result.status)
        if !$scope.list
          $scope.list = result.results;
        else if result.results and result.results.length
          result.results.forEach (item)->
            $scope.list.push item
        else
          showAlert '没有更多的数据了'
      else
        showAlert result.error

  $scope.getList()

  $scope.updateStatus = (data) ->
    $scope.updating = true
    data.disabled = !data.disabled
    $http.post(updateStatusUri,{_id:data._id, disabled:data.disabled}).success (result) ->
      showAlert result.error unless result.status
      $scope.updating = false

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getList()

  $scope.songs = []

  $scope.choose = (song)->
    has = false
    $scope.songs.forEach (s)->
      if s._id == song._id
        has = true
    if !has
      $scope.songs.push song

  $scope.dataGrid =
    data:'list'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    enableHighlighting:true
    rowHeight:40
    columnDefs:[
      {field: "name", displayName:"名称", cellTemplate: textCellTemplate}
      {field: "handler", displayName: "操作", width:100, cellTemplate: '<div class="row text-center pagination-centered" ng-style="{height: rowHeight}">
                        <a style="margin-top: 3px" class="btn btn-success btn-xs" ng-click="choose(row.entity)">选择</a>
                        </div></div>'}
    ]

  $scope.tags = []
  getDict $http, 'SongTags', (result) ->
    if result and result.list and result.list.length
      result.list.forEach (tag) ->
        console.log tag
        if typeof tag == 'string'
          $scope.tags.push text:tag
        else
          $scope.tags.push tag

  $scope.loadTags = (query) ->
    deffered = $q.defer()
    deffered.resolve $filter('filter') $scope.tags, query
    return deffered.promise

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.ok = ->
    $modalInstance.close($scope.songs)
    return

angular.element(document).ready ->
  angular.bootstrap document.getElementById("menuDiv"), ['MenuApp']