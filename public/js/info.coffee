info = angular.module 'InfoApp', ['ngGrid', 'ui.bootstrap', 'angularFileUpload', 'ngRoute', 'textAngular']
info.value 'Info', {}
info.config ($routeProvider, $provide)->
  $routeProvider
  .when '/',templateUrl:'infoList.html',controller:'InfoCtrl'
  .when '/new',templateUrl:'templates/html/editor.html',controller:'EditorCtrl'
  .when '/edit',templateUrl:'templates/html/editor.html',controller:'EditorCtrl'

  $provide.decorator('taOptions', ['taRegisterTool', '$delegate', (taRegisterTool, taOptions)->
    taRegisterTool 'im',
      iconclass: 'fa fa-picture-o'
      action: ($deferred)->
        this.$editor().$parent.launch('insertImage', $deferred.resolve, this.$editor().wrapSelection)
    taOptions.toolbar[1].push 'im'
    return taOptions
  ])

info.controller 'InfoAppCtrl', ($scope,$location, Info)->
  $location.path '/'
  $scope.edit = (data) ->
    angular.extend Info, data
    $location.path '/edit'

  $scope.add = ->
    $location.path '/new'

info.controller 'EditorCtrl', ($scope, $http, $timeout, Info, $upload, $modal, $location)->
  GetToken($http, (result) ->
    if result
      $scope.token = result
    return
  )

  $scope.textAreaSetup = ($element)->
    angular.element(document).ready ->
      $element.focus()

  $scope.Info = Info

  showMsg = (msg)->
    $scope.msg = msg
    $timeout(->
      $scope.msg = ''
    , 3000)

  if Info._id
    Info.htmlContent = Info.content

  $scope.preview = ->
    console.log 'preview'
    modalInstance = $modal.open(
      templateUrl:'qrcode.html'
      controller:QRcodeCtrl
      resolve:
        url:->imgHost+Info.url
    )
  $scope.cancel = ->
    for p of Info
      delete Info[p]
    $location.path '/'
  $scope.save = (status)->
    unless Info.title
      return showMsg('标题不能为空')
    $scope.updating = true
    unless Info._id
      $http.post('/info/add',{title:Info.title, content:Info.htmlContent}).success (result) ->
        console.log result
        $scope.updating = false
        if result.status
          showMsg('保存成功')
          angular.extend Info, result.result
          console.log result.result
          if status
            $location.path '/'
        else
          showMsg(result.error)
    else
      $http.post('/info/update',{_id:Info._id, title:Info.title, content:Info.htmlContent}).success (result) ->
        console.log result.status
        $scope.updating = false
        if result.status
          showMsg('保存成功')
          angular.extend Info, result.result
          console.log result.result
          if status
            $location.path '/'
        else
          showMsg(result.error)

  $scope.launch = (name, finishFunction, wrapSelection)->
    console.log wrapSelection, finishFunction
    modalInstance = $modal.open(
      templateUrl:'modal.html'
      backdrop:'static'
      controller:ModalInstanceCtrl
      resolve:
        upload:->$upload
        token:->$scope.token
    )
    modalInstance.result.then ((data) ->
      console.log data
      if data
        wrapSelection 'insertImage', imgHost+data.key, true
        finishFunction()
      return
    ), ->
      return


uploader = ''

QRcodeCtrl = ($scope, url, $timeout)->
  $scope.url = url
  $timeout(->
    jQuery('#qrcode').qrcode(url)
  , 500)

ModalInstanceCtrl = ($scope, $modalInstance, upload, token, $timeout) ->
  $scope.data = confirm:'上传'
  console.log 'info', $scope.data

  $scope.buttonDisabled = true

  $scope.ok = ->
    console.log 'ok'
    if $scope.data.uploaded
      $modalInstance.close($scope.data)

  $timeout(->
    console.log 'init uploader', $('#p1')
    uploader = Qiniu.uploader(
      runtimes: 'html5,flash,html4'
      browse_button: 'p1'
      uptoken:token
      unique_names: true
      domain: imgHost
      container: 'c1'
      max_file_size: '10mb'
      flash_swf_url: 'js/plupload/Moxie.swf'
      max_retries: 1
      auto_start: true
      init:
        'FileUploaded':(up, file, info)->
          console.log info, $scope.data
          data = angular.fromJson info
          $timeout(->
            $scope.data.key = data.key
            $scope.data.url = imgHost+data.key+'?imageView2/1/w/100/h/100'
            $scope.data.uploaded = true
            $scope.buttonDisabled = false
          , 500)
        'Error':(up, err, errTip)->
          console.log up, err, errTip
    )
  , 500)

  $scope.cancel = ->
    $modalInstance.close()
    return

info.controller 'InfoCtrl', ($scope, $http, $location) ->

  $scope.search = ->
    $scope.page = 1
    $scope.infos = null
    $scope.getInfos()

  $scope.getInfos = ->
    $http.get('/info/list', params:title:$scope.titleSearch,page:$scope.page,perPage:20).success (result) ->
      if(result.status)
        if !$scope.infos
          $scope.infos = result.results;
        else if result.results and result.results.length
          result.results.forEach (info)->
            $scope.infos.push info
        else
          showAlert '没有更多的数据了'
      else
        showAlert result.results

  $scope.getInfos()

  configScopeForNgGrid $scope

  $scope.updateStatus = (data) ->
    $scope.updating = true
    data.disabled = !data.disabled
    $http.post('/info/update/status',{_id:data._id, disabled:data.disabled}).success (result) ->
      console.log result.status
      $scope.updating = false

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getInfos()

  $scope.infoGrid =
    data:'infos'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    columnDefs:[
      {field: "title", displayName:"标题", cellTemplate: textCellTemplate}
      {field: "creator.username", width:88, displayName:"创建者", cellTemplate: textCellTemplate}
      {field: "created_at", width:100, displayName:"创建时间", cellTemplate: dateCellTemplate}
      {field: "updator.username", width:88, displayName:"更新者", cellTemplate: textCellTemplate}
      {field: "updated_at", width:100, displayName:"更新时间", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "操作", width:100, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
<div class="col-md-8 col-md-offset-2" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
<a class="btn btn-primary btn-xs col-md-5" ng-click="edit(row.entity)">编辑</a>
<a class="btn btn-xs col-md-5 col-md-offset-2" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'}
    ]

  return

angular.bootstrap document.getElementById("infoDiv"), ['InfoApp']