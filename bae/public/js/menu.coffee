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
    $http.get(listUri, params:type:1,name:$scope.menuName,tags:tags,page:$scope.page,perPage:20).success (result) ->
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
    if !data.disabled
      confirm 2, '歌单状态更新', '是否确认禁用该歌单，一旦禁用后客户将不能再不会再使用该歌单', (value)->
        if value
          updateStatus(data)
    else
      updateStatus(data)

  updateStatus = (data)->
    $scope.updating = true
    data.disabled = !data.disabled
    $http.post(updateStatusUri,{_id:data._id, disabled:data.disabled}).success (result) ->
      showAlert result.error unless result.status
      $scope.updating = false

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    if $scope.module == 'templates/html/menu/home.html'
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
      {field: "handler", displayName: "操作", width:150, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
                  <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
                    <a class="btn btn-info btn-xs" ng-click="clients(row.entity)">客户</a>
                    <a class="btn btn-primary btn-xs" ng-click="edit(row.entity)">编辑</a>
                    <a class="btn btn-xs" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'}
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
    time = name:'默认时段', active:true, songs:[]
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
    time = name:'新增时段',songs:[]
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
          if !time.isValid()
            wrong = true
    if wrong
      confirm(1, '时段开始或结束时间格式不对', '注意冒号格式，应该是 8:00或18:00 这样的')
      return false
    else
      return true

  $scope.addSong = ->
    if validateTime($scope.time.begin)
      $scope.open()

  $scope.tags = []
  getDict $http, 'MenuTags', (result) ->
    if result and result.list and result.list.length
      result.list.forEach (tag) ->
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
    begin = $scope.time.begin
    if !begin
      return
    i = 0
    h = begin.split(':')[0]
    m = begin.split(':')[1]
    time = moment(hour:parseInt(h),minute:parseInt(m))
    songs.sort (a, b)->
      return a.index-b.index
    while i < songs.length
      song = songs[i]
      song.index = i
      song.time = time.format('HH:mm:ss')
      if song.song.duration
        time.add 's', song.song.duration
      i++
    time.add 'm', 1
    $scope.time.end = time.format('HH:mm')

  $scope.saveMenu = ->
    menu = angular.copy $scope.data
    if !menu.name
      wrong = '歌单名称不能为空'
    if menu.quality
      wrong = '歌曲质量目前仅支持64和192两种' if parseInt(menu.quality) != 64 && parseInt(menu.quality) != 192
    if wrong
      return confirm(1, '保存失败', wrong)
    else
      list = menu.list
      list.forEach (list)->
        songs = list.songs
        if songs
          songs.forEach (s)->
            s.song = s.song._id
      tags = []
      if menu.tags
        menu.tags.forEach (tag)->
          if typeof tag == 'string'
            tags.push(tag)
          else
            tags.push(tag.text)
      menu.tags = tags
      menu.type = 1
      $scope.handling = true
      if !menu._id
        $http.post('/menu/add',menu).success (result) ->
          console.log 'save menu3', result
          showAlert result.error unless result.status
          $scope.data = result.results
          $scope.handling = false
          confirm(2, '保存成功', '继续编辑或返回歌单列表', (value)->
            if(!value)
              $scope.back()
          , '继续编辑', '返回列表')
      else
        $http.post('/menu/update',menu).success (result) ->
          $scope.handling = false
          showAlert result.error unless result.status
          confirm(2, '保存成功', '继续编辑或返回歌单列表', (value)->
            if(!value)
              $scope.back()
          , '继续编辑', '返回列表')

  $scope.clients = (menu)->
    modalInstance = $modal.open(
      templateUrl:'clients.html'
      controller:ClientsModalInstanceCtrl
      backdrop:'static'
      resolve:
        menu:->menu
    )
    modalInstance.result.then ((clients) ->
      if clients
        $http.post('/menu/update',{_id:menu._id,clients:clients}).success (result) ->
          showAlert result.error unless result.status
          $scope.search()
    ), ->
      return

  getSongs = ->
    allsongs = []
    data = $scope.data
    if data.list && data.list.length
      data.list.forEach (list)->
        if list.songs && list.songs.length
          list.songs.forEach (song)->
            allsongs.push song.song._id
    return allsongs

  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl:'modal.html'
      controller:ModalInstanceCtrl
      backdrop:'static'
      resolve:
        all:getSongs
        songs: ->
          arr = []
          $scope.time.songs.forEach (s)->
            if s.song.duration
              arr.push s.song
          return arr
    )
    modalInstance.result.then ((data) ->
      if data
        time = $scope.time
        time.songs = [] unless time.songs
        allsongs = getSongs()
        data.forEach (s)->
          has = false
          if allsongs.indexOf(s._id) != -1
              has = true
          time.songs.push(song:s) unless has
        $scope.refreshSongList()
      return
    ), ->
      return

ClientsModalInstanceCtrl = ($scope, $http, $timeout, $modalInstance,$q, $filter, menu) ->
  listUri = '/user/list'
  configScopeForNgGrid $scope

  menu = angular.copy menu
  $scope.clients = menu.clients

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
    $http.get(listUri, params:username:$scope.searchText,tags:tags,page:$scope.page,perPage:20).success (result) ->
      if(result.status)
        if !$scope.list
          $scope.list = result.results;
          refreshStatus()
        else if result.results and result.results.length
          result.results.forEach (item)->
            $scope.list.push item
          refreshStatus()
        else
          showAlert '没有更多的数据了'
      else
        showAlert result.error

  refreshStatus = ->
    $scope.list.forEach (item)->
      item.style = choosedStyle(item)
      item.label = choosedLabel(item)

  $scope.getList()

  $scope.tags = []
  getDict $http, 'ClientTags', (result) ->
    if result and result.list and result.list.length
      result.list.forEach (tag) ->
        if typeof tag == 'string'
          $scope.tags.push text:tag
        else
          $scope.tags.push tag

  $scope.loadTags = (query) ->
    deffered = $q.defer()
    deffered.resolve $filter('filter') $scope.tags, query
    return deffered.promise

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getList()

  choosed = (data)->
    has = false
    $scope.clients.forEach (c)->
      if c == data._id
        has = true
    return has

  choosedStyle = (data)->
    return if choosed(data) then 'btn-warning' else 'btn-success'

  choosedLabel = (data)->
    return if choosed(data) then '取消' else '选中'

  $scope.handle = (data)->
    if choosed(data)
      i = 0
      while i < $scope.clients.length
        if $scope.clients[i] == data._id
          $scope.clients.splice(i, 1)
        i++
    else
      $scope.clients.push data._id if $scope.clients.indexOf(data._id) == -1
    refreshStatus()

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.ok = ->
    $modalInstance.close($scope.clients)
    return

  $scope.dataGrid =
    data:'list'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    enableHighlighting:true
    rowHeight:40
    columnDefs:[
      {field: "username", displayName:"客户名称", cellTemplate: textCellTemplate}
      {field: "parent.username", displayName:"总部", cellTemplate: textCellTemplate}
      {field: "tags", displayName:"标签", cellTemplate: textCellTemplate}
      {field: "handler", displayName: "操作", width:100, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
            <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
            <a class="btn btn-xs" ng-class="row.entity.style" ng-click="handle(row.entity)" ng-disabled="updating">{{ row.entity.label }}</a></div></div>'}
    ]

ModalInstanceCtrl = ($scope, $http, $timeout, $modalInstance,$q, $filter, songs, all) ->

  listUri = '/song/list'
  updateStatusUri = '/song/update/status'
  configScopeForNgGrid $scope

  $scope.title = '插入媒资'
  $scope.songs = angular.copy songs
  console.log $scope.songs

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
          refreshStatus()
        else if result.results and result.results.length
          result.results.forEach (item)->
            $scope.list.push item
          refreshStatus()
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

  refreshStatus = ->
    $scope.list.forEach (item)->
      if all
        if all.indexOf(item._id) != -1
          item.choosed = true
      console.log all, item._id
      if !item.choosed
        item.style = choosedStyle(item)
        item.label = choosedLabel(item)

  choosed = (data)->
    has = false
    $scope.songs.forEach (c)->
      if c._id == data._id
        has = true
    return has

  choosedStyle = (data)->
    return if choosed(data) then 'btn-warning' else 'btn-success'

  choosedLabel = (data)->
    return if choosed(data) then '取消' else '选中'

  $scope.handle = (data)->
    if choosed(data)
      i = 0
      while i < $scope.songs.length
        if $scope.songs[i]._id == data._id
          $scope.songs.splice(i, 1)
        i++
    else
      $scope.songs.push data
    refreshStatus()

  $scope.try = (data)->
    window.open(imgHost+data.url+'?pfop/avthumb/mp3/ab/64k')
    return true

  $scope.dataGrid =
    data:'list'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    enableHighlighting:true
    rowHeight:40
    columnDefs:[
      {field: "name", displayName:"名称", cellTemplate: textCellTemplate}
      {field: "handler", displayName: "操作", width:100, cellTemplate: '
      <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
        <a class="btn btn-default btn-xs" ng-click="try(row.entity)">试听</a>
        <a ng-if="!row.entity.choosed" class="btn btn-success btn-xs" ng-class="row.entity.style" ng-click="handle(row.entity)">{{ row.entity.label }}</a>
      </div></div>'}
    ]

  $scope.tags = []
  getDict $http, 'SongTags', (result) ->
    if result and result.list and result.list.length
      result.list.forEach (tag) ->
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