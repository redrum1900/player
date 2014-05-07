question = angular.module 'QuestionApp', ['ngGrid', 'ui.bootstrap', 'angularFileUpload']
question.controller 'QuestionCtrl', ($scope, $http, $modal, $upload) ->

  configScopeForQuestionType $scope

  GetToken($http, (result) ->
    if result
      $scope.token = result
    return
  )

  $scope.search = ->
    $scope.page = 1
    $scope.questions = null
    $scope.getQuestions()

  $scope.getQuestions = ->
    $http.get('/question/list', params:title:$scope.titleSearch,page:$scope.page,perPage:20).success (result) ->
      console.log result
      if(result.status)
        if !$scope.questions
          $scope.questions = result.results;
        else if result.results and result.results.length
          result.results.forEach (question)->
            $scope.questions.push question
        else
          showAlert '没有更多的数据了'
      else
        showAlert result.results

  $scope.getQuestions()

  configScopeForNgGrid $scope

  $scope.updateStatus = (data) ->
    $scope.updating = true
    data.disabled = !data.disabled
    $http.post('/question/update/status',{_id:data._id, disabled:data.disabled}).success (result) ->
      console.log result.status
      $scope.updating = false

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getQuestions()

  $scope.questionGrid =
    data:'questions'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    rowHeight:40
    columnDefs:[
      {field: "title", displayName:"标题", cellTemplate: textCellTemplate}
      {field: "type", displayName:"类型", width:48, cellTemplate: questionTypeTemplate}
      {field: "image", displayName:"配图", width:45, cellTemplate: imgCellTemplate}
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
    $scope.data = {answers:[]}
    $scope.open()
    return

  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl:'modal.html'
      backdrop:'static'
      controller:ModalInstanceCtrl
      resolve:
        types:->$scope.types
        data:->$scope.data
        upload:->$upload
        token:->$scope.token
        http:->$http
    )
    modalInstance.result.then ((data) ->
      $scope.questions = [] unless $scope.questions
      if data == 'refresh'
        $scope.questions = null
        $scope.page = 1
        $scope.getQuestions()
      else if data
        $scope.questions.unshift data
      return
    ), ->
      return
    return
  return

angular.bootstrap document.getElementById("questionDiv"), ['QuestionApp']

ModalInstanceCtrl = ($scope, $modalInstance, types, data, upload, token, http) ->
  $scope.types = types

  http.get '/dict/get', params:key:'QUserPros'
    .success (result) ->
      if result.status
        $scope.user_pros = result.results.list
      else
        showAlert result.error

  $scope.data = data
  $scope.buttonDisabled = false

  if data.title
    $scope.update = true
    $scope.title = '编辑问题'
  else
    $scope.title = '新增问题'

  $scope.addOption = ->
    $scope.data.answers.push content:'',image:'',need_reason:false
    return

  $scope.delete = (option) ->
    $scope.data.answers.splice $scope.data.answers.indexOf(option), 1

  $scope.change = (u) ->
    $scope.user_pro = u

  $scope.onFileSelected = ($files, option)->

    ((file) ->
      $scope.buttonDisabled = true
      upload.upload(
        url:uploadHost
        data:
          token:token
          key:new Date()+'.jpg'
        file:file
      ).progress((evt) ->
        console.log evt
#        console.log "percent: " + parseInt(100.0 * evt.loaded / evt.total)
        return
      ).success((data, status, headers, config) ->
        if status == 200
          option.image = imgHost+data.key+'?imageView2/1/w/30/h/30'
        $scope.buttonDisabled = false
        return
      )
      return
    ) file for file in $files
    return


  $scope.addImage = ->
    return

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.$watch 'data.type', (nv, ov)->
    console.log nv
    if nv == 4
      $scope.choose4 = true
    else
      $scope.choose4 = false

  $scope.ok = ->
    console.log data
    unless $scope.data.type
      msg = '您还没选择题目类型'
    else unless $scope.data.title
      msg = '请输入题目标题'
    else if data.type == 4 && parseInt(data.score) == 0
      msg = '评分不能为0'
    else ((option) ->
        if not option.content and not option.image
          msg = '选项的内容或图片必填一项';
      ) option for option in $scope.data.answers
    if(msg)
      $scope.msg = msg
      return
    else
      $scope.buttonDisabled = true
      if $scope.update
        http.post('/question/update', $scope.data).success((result) ->
          if result.status
            $modalInstance.close 'refresh'
          else
            $scope.msg = result.results
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
      else
        http.post('/question/add', $scope.data).success((result) ->
          if result.status
            $modalInstance.close result.results
          else
            $scope.msg = result.results
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
    return


  return