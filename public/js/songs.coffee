songs = angular.module 'SongMApp', ['ngGrid', 'ngTagsInput', 'ui.bootstrap']
songs.controller 'SongMCtrl', ($scope, $http, $modal) ->

  listUri = '/song/list'
  updateStatusUri = '/song/update/status'
  configScopeForNgGrid $scope

  $scope.search = ->
    $scope.page = 1
    $scope.list = null
    $scope.getList()

  $scope.getList = ->
    $http.get(listUri, params:songname:$scope.searchText,page:$scope.page,perPage:20).success (result) ->
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
      {field: "id3", displayName:"歌曲信息", cellTemplate: textCellTemplate}
      {field: "creator.username", width:88, displayName:"创建者", cellTemplate: textCellTemplate}
      {field: "created_at", width:100, displayName:"创建时间", cellTemplate: dateCellTemplate}
      {field: "updator.username", width:88, displayName:"更新者", cellTemplate: textCellTemplate}
      {field: "updated_at", width:100, displayName:"更新时间", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "操作", width:100, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
      <div class="col-md-8 col-md-offset-2" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
      <a class="btn btn-primary btn-xs col-md-5" ng-click="edit(row.entity)">编辑</a>
      <a class="btn btn-xs col-md-5 col-md-offset-2" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'}
    ]

  $scope.edit = (data) ->
    $scope.data = data
    $scope.open()

  $scope.add = ->
    $scope.data = {}
    $scope.open()
    return

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


  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl:'modal.html'
      controller:ModalInstanceCtrl
      backdrop:'static'
      resolve:
        data:->$scope.data
        http:->$http
    )
    modalInstance.result.then ((data) ->
      $scope.list = [] unless $scope.list
      if data == 'refresh'
        $scope.list = null
        $scope.page = 1
        $scope.getList()
      else if data
        $scope.list.unshift data
      return
    ), ->
      return
    return
  return

angular.bootstrap document.getElementById("songMDiv"), ['SongMApp']

ModalInstanceCtrl = ($scope, $timeout, $modalInstance, data, http) ->

  $scope.data = data
  $scope.buttonDisabled = false

  getParents = ->
    http.get('/song/parents').success (result)->
      $scope.parents = result.result
  getParents()

  if data._id
    $scope.update = true
    $scope.title = '编辑客户'
  else
    $scope.title = '新增客户'

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.select = (value) ->
    $scope.selectedType = value;
    return

  $scope.ok = ->
    unless $scope.data.songname
      msg = '客户名称必填'
    if(msg)
      $scope.msg = msg
      return
    else
      $scope.buttonDisabled = true
      if $scope.update
        http.post('/song/update', $scope.data).success((result) ->
          if result.status
            $modalInstance.close 'refresh'
          else
            $scope.msg = result.results
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
      else
        http.post('/song/add', $scope.data).success((result) ->
          if result.status
            $modalInstance.close result.results
          else
            $scope.msg = result.error
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
    return

  return