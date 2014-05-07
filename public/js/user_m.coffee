user_m = angular.module 'UserMApp', ['ngGrid', 'ui.bootstrap']
user_m.controller 'UserMCtrl', ($scope, $http, $modal) ->

  listUri = '/user/list'
  updateStatusUri = '/user/update/status'
  configScopeForNgGrid $scope

  $scope.search = ->
    $scope.page = 1
    $scope.list = null
    $scope.getList()

  $scope.getList = ->
    $http.get(listUri, params:username:$scope.searchText,page:$scope.page,perPage:20).success (result) ->
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
    rowHeight:40
    columnDefs:[
      {field: "udid", displayName:"设备号", cellTemplate: textCellTemplate}
      {field: "username", displayName:"用户名", cellTemplate: textCellTemplate}
      {field: "mobile", displayName:"手机号", width:115, cellTemplate: textCellTemplate}
      {field: "email", displayName:"邮箱", cellTemplate: textCellTemplate}
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

angular.bootstrap document.getElementById("userMDiv"), ['UserMApp']

ModalInstanceCtrl = ($scope, $modalInstance, data, http) ->

  data.tempPros = {}
  if data.pros
    data.pros.forEach (pro) ->
      data.tempPros[pro.key] = pro.value

  getOptions = (key, callback, subKey, valuePro) ->
    getDict http, key, (result) ->
      if subKey
        if result and valuePro
          $scope[subKey][key] = result[valuePro]
        else
          $scope[subKey][key] = result
        console.log $scope[subKey]
      else
        $scope[key] = result
      callback result if result and callback
    return

  getOptions 'UserFrom'
  $scope.Pros = {}
  getOptions 'UserExtraPro', (result) ->
    if result and result.list and result.list.length
      ((pro) ->
        getOptions pro, null, 'Pros', 'list'
      ) pro for pro in result.list

  $scope.data = data
  $scope.buttonDisabled = false

  if data._id
    $scope.update = true
    $scope.title = '编辑用户'
  else
    $scope.title = '新增用户'

  #日期
  configDateForScope $scope
  $scope.maxDate = new Date()
  $scope.open = ($event) ->
    $scope.opened = true

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.select = (value) ->
    $scope.selectedType = value;
    return

  $scope.ok = ->
    for k of data.tempPros
      data.pros = [] unless data.pros
      data.pros.push key:k,value:data.tempPros[k]
    console.log data
    unless $scope.data.username or $scope.data.mobile
      msg = '用户名和手机号必填一项'
    else unless $scope.data.come_from
      msg = '请选择用户来源'
    if(msg)
      $scope.msg = msg
      return
    else
      delete data['tempPros']
      $scope.buttonDisabled = true
      if $scope.update
        http.post('/user/update', $scope.data).success((result) ->
          if result.status
            $modalInstance.close 'refresh'
          else
            $scope.msg = result.results
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
      else
        http.post('/user/add', $scope.data).success((result) ->
          if result.status
            $modalInstance.close result.results
          else
            $scope.msg = result.results
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
    return

  return