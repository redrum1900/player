client = angular.module 'UserMApp', ['ngGrid', 'ui.bootstrap', 'ngTagsInput']
client.controller 'UserMCtrl', ($scope, $http, $modal, $q, $filter) ->

  listUri = '/user/list'
  updateStatusUri = '/user/update/status'
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
    $http.get(listUri, params:username:$scope.searchText,tags:tags,page:$scope.page,perPage:20).success (result) ->
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

  $scope.tags = []
  getDict $http, 'ClientTags', (result) ->
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

  $scope.updateStatus = (data) ->
    if !data.disabled
      confirm 2, '客户状态更新', '是否确认禁用该客户，一旦禁用后该客户将不能使用软件', (value)->
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
      {field: "username", displayName:"客户名称", cellTemplate: textCellTemplate}
      {field: "code", displayName:"客户密码", cellTemplate: textCellTemplate}
      {field: "parent.username", displayName:"总部", cellTemplate: textCellTemplate}
      {field: "tags", displayName:"标签", cellTemplate: textCellTemplate}
      {field: "man", displayName:"联系人", cellTemplate: textCellTemplate}
      {field: "mobile", displayName:"手机号", width:115, cellTemplate: textCellTemplate}
      {field: "email", displayName:"邮箱", cellTemplate: textCellTemplate}
      {field: "creator.username", width:88, displayName:"创建者", cellTemplate: textCellTemplate}
      {field: "created_at", width:100, displayName:"创建时间", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "操作", width:100, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
      <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
      <a class="btn btn-primary btn-xs " ng-click="edit(row.entity)">编辑</a>
      <a class="btn btn-xs" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'}
    ]

  $scope.edit = (data) ->
    $scope.data = data
    $scope.open()

  $scope.add = ->
    $scope.data = {}
    $scope.open()
    return

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

angular.bootstrap document.getElementById("userMDiv"), ['UserMApp']

ModalInstanceCtrl = ($scope, $timeout, $modalInstance, data, http, tags, $q, $filter) ->

  $scope.data = data
  $scope.buttonDisabled = false
  $scope.tags = tags

  getParents = ->
    http.get('/user/parents').success (result)->
      $scope.parents = result.result
  getParents()

  if data._id
    $scope.update = true
    $scope.title = '编辑客户'
  else
    $scope.title = '新增客户'

  $scope.loadTags = (query) ->
    deffered = $q.defer()
    deffered.resolve $filter('filter') $scope.tags, query
    return deffered.promise

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.select = (value) ->
    $scope.selectedType = value;
    return

  $scope.ok = ->
    data = angular.copy $scope.data
    unless data.username
      msg = '客户名称必填'
    if(msg)
      $scope.msg = msg
      return
    else
      tags = []
      if data.tags
        data.tags.forEach (tag)->
          if typeof tag == 'string'
            tags.push(tag)
          else
            tags.push(tag.text)
      data.tags = tags
      $scope.buttonDisabled = true
      if $scope.update
        delete data['parent']
        http.post('/user/update', data).success((result) ->
          if result.status
            $modalInstance.close 'refresh'
          else
            $scope.msg = result.results
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
      else
        http.post('/user/add', data).success((result) ->
          if result.status
            $modalInstance.close result.results
          else
            $scope.msg = result.results
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
    return

  return