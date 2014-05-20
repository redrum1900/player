songs = angular.module 'SongApp', ['ngGrid', 'ngRoute', 'ngTagsInput', 'ui.bootstrap']
songs.controller 'SongCtrl', ($scope, $http, $modal, $q, $filter) ->

  listUri = '/song/list'
  updateStatusUri = '/song/update/status'
  configScopeForNgGrid $scope

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
        tags:->$scope.tags
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

ModalInstanceCtrl = ($scope, $timeout, $modalInstance, data, tags, http,$q, $filter) ->

  $scope.data = data
  $scope.buttonDisabled = false
  $scope.tags = tags
  $scope.label = '上传媒资'

  if data._id
    $scope.update = true
    $scope.title = '编辑媒资'
    $scope.cover = imgHost+$scope.data.cover+'?imageView2/1/w/200/h/200'
  else
    $scope.title = '新增媒资'

  $scope.loadTags = (query) ->
    deffered = $q.defer()
    deffered.resolve $filter('filter') $scope.tags, query
    return deffered.promise

  $timeout(->
    uploader = Qiniu.uploader(
      runtimes: 'html5,flash,html4'
      browse_button: 'p1'
      uptoken_url:'/upload/token/mp3'
      unique_names: true
      domain: imgHost
      container: 'c1'
      max_file_size: '10mb'
      flash_swf_url: 'js/plupload/Moxie.swf'
      dragdrop:true
      drop_element:'c1'
      max_retries: 1
      auto_start: true
      init:
        'BeforeUpload': (up, file)->
          $scope.buttonDisabled = true
        'FileUploaded':(up, file, info)->
          data = angular.fromJson info
          console.log data
          $timeout(->
            $scope.data.url = data.key
            $scope.data.size = file.size
            $scope.label = '上传成功'
            $scope.buttonDisabled = false
            http.get('http://yfcdn.qiniudn.com/'+data.key+'?avinfo').success (result)->
              $scope.data.duration = result.format.duration
              console.log $scope.data
          , 500)
        'UploadProgress':(up,file)->
          $scope.label = file.percent + "%"
        'Error':(up, err, errTip)->
          $scope.msg = err
          $scope.buttonDisabled = false
    )

    $scope.imgProgress = '上传封面'

    uploader2 = Qiniu.uploader(
      runtimes: 'html5,flash,html4'
      browse_button: 'p2'
      uptoken_url:'/upload/token'
      unique_names: true
      domain: imgHost
      container: 'c2'
      max_file_size: '10mb'
      flash_swf_url: 'js/plupload/Moxie.swf'
      dragdrop:true
      drop_element:'c2'
      max_retries: 1
      auto_start: true
      init:
        'BeforeUpload': (up, file)->
          $scope.buttonDisabled = true
        'FileUploaded':(up, file, info)->
          data = angular.fromJson info
          console.log data
          $timeout(->
            $scope.data.cover = data.key
            $scope.cover = imgHost+$scope.data.cover+'?imageView2/1/w/200/h/200'
            $scope.buttonDisabled = false
            $scope.imgProgress = '上传封面'
          , 500)
        'UploadProgress':(up,file)->
          $scope.imgProgress = file.percent + "%"
        'Error':(up, err, errTip)->
          $scope.msg = err
          $scope.buttonDisabled = false
    )
  , 500)

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.ok = ->

    if !$scope.data.name
      msg = '媒资名称必填'
    else if !$scope.data.url
      msg = '媒资尚未上传'
    else if !$scope.data.cover
      msg = '媒资封面尚未添加'
    if(msg)
      $scope.msg = msg
      return
    else
      $scope.buttonDisabled = true
      tags = []
      if $scope.data.tags
        $scope.data.tags.forEach (tag)->
          if typeof tag == 'string'
            tags.push(tag)
          else
            tags.push(tag.text)
      $scope.data.tags = tags
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

angular.element(document).ready ->
  angular.bootstrap document.getElementById("songDiv"), ['SongApp']