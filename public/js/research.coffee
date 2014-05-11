research = angular.module 'ResearchApp', ['ngGrid', 'ngTagsInput', 'ui.bootstrap', 'ngRoute']
research.value 'Research', {}
research.controller 'ResearchCtrl', ($scope, $http, $modal, $route, $routeParams, Research, $location) ->

  $scope.$routeParams = $routeParams
  $scope.$route = $route
  $location.path ''

  $scope.status = 'all'

  $scope.$watch 'status', ->
    $scope.researches = undefined
    $scope.getList()

  $scope.search = ->
    $scope.page = 1
    $scope.researches = null
    $scope.getList()

  $scope.getList = ->
    $http.get('/research/list', params:name:$scope.searchText,page:$scope.page,perPage:20,status:$scope.status).success (result) ->
      if(result.status)
        if !$scope.researches
          $scope.researches = result.results;
        else if result.results and result.results.length
          result.results.forEach (research)->
            $scope.researches.push research
        else
          showAlert '没有更多的数据了'
      else
        showAlert result.results

#  $scope.getList()

  configScopeForNgGrid $scope
  configScopeForNgGrid $scope

  $scope.updateStatus = (data) ->
    $scope.updating = true
    data.disabled = !data.disabled
    $http.post('/research/update/status',{_id:data._id, disabled:data.disabled}).success (result) ->
      $scope.updating = false

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getList()

  $scope.researchGrid =
    data:'researches'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    rowHeight:40
    columnDefs:[
      {field: "name", displayName:"名称", cellTemplate: textCellTemplate}
      {field: "participation_num", displayName:"参与人数", width:68, cellTemplate: textCellTemplate}
      {field: "creator.username", width:88, displayName:"创建者", cellTemplate: textCellTemplate}
      {field: "created_at", width:100, displayName:"创建时间", cellTemplate: dateCellTemplate}
      {field: "updator.username", width:88, displayName:"更新者", cellTemplate: textCellTemplate}
      {field: "updated_at", width:100, displayName:"更新时间", cellTemplate: dateCellTemplate}
      {field: "begin_date", width:100, displayName:"起始时间", cellTemplate: dateCellTemplate}
      {field: "end_date", width:100, displayName:"截止时间", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "操作", width:160, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
<div class="col-md-8 col-md-offset-2" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
<a class="btn btn-success btn-xs col-md-4" ng-click="edit(row.entity)">编辑</a>
<a class="btn btn-info btn-xs col-md-4" ng-click="rebuild(row.entity)">重建</a>
<a class="btn btn-xs col-md-4" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'}
    ]

  isRebuild = false

  $scope.edit = (data) ->
    angular.extend Research, data
    isRebuild = false
    $scope.open()

  $scope.rebuild = (data) ->
    angular.extend Research, data
    isRebuild = true
    $scope.open()

  $scope.add = ->
    Research = {}
    isRebuild = false
    $scope.open()
    return

  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl:'modal.html'
      backdrop:'static'
      controller:ModalInstanceCtrl
      resolve:
        http:->$http
        route:->$route
        research:->Research
        location:->$location
        isRebuild:->isRebuild
    )
    modalInstance.result.then ((data) ->
      $location.path ''
      $scope.researches = [] unless $scope.researches
      if data == 'refresh'
        $scope.researches = null
        $scope.page = 1
        $scope.getList()
      else if data
        $scope.researches.unshift data
      return
    ), ->
      $location.path ''
      return
    return
  return

research.config ($routeProvider) ->
  $routeProvider
    .when '/',templateUrl:'templates/html/step1.html',controller:'Step1Ctrl'
    .when '/step2',templateUrl:'templates/html/step2.html',controller:'Step2Ctrl'
    .when '/step3',templateUrl:'templates/html/step3.html',controller:'Step3Ctrl'

research.controller 'Step1Ctrl', ($scope, $http, $q, $filter, $routeParams, Research) ->
  configDateForScope $scope
  $scope.Research = Research #研究对象
  # 研究标签
  $scope.tags = []
  getDict $http, 'ResearchTags', (result) ->
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

research.controller 'Step2Ctrl', ($scope, $http, Research) ->
  $scope.Research = Research
  configScopeForNgGrid $scope
  configScopeForQuestionType $scope

  gotQuestions = undefined #所有从后台获取的问题详情数组
  Research.questions = [] unless Research.questions
  $scope.choosedQuestions = Research.questions #所有选中的问题ID数组

  $scope.search = ->
    $scope.page = 1
    $scope.questions = null
    $scope.getQuestions()

  $scope.getQuestions = ->
    $http.get('/question/list', params:title:$scope.titleSearch,page:$scope.page,perPage:10).success (result) ->
      if(result.status)
        if !$scope.questions
          $scope.questions = result.results;
          unless gotQuestions
            gotQuestions = $scope.questions.concat()
            Research.gotQuestions = gotQuestions
          $scope.judgeQeustionIfChoosed()
        else if result.results and result.results.length
          result.results.forEach (question)->
            $scope.questions.push question
          $scope.judgeQeustionIfChoosed()
        else
          $scope.page -= 1
          $scope.$emit 'error', '没有更多的数据了'
      else
        $scope.$emit 'error', result.error

  $scope.page = 1
  $scope.getQuestions()

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getQuestions()

  $scope.judgeQeustionIfChoosed = ->
    if $scope.questions and $scope.choosedQuestions
      $scope.questions.forEach (question) ->
        question.choosed = $scope.choosedQuestions.indexOf(question._id) != -1
        gotQuestions.push question if gotQuestions.indexOf question == -1

  $scope.checked = (question) ->
    if question.choosed
      $scope.choosedQuestions.push question._id
    else if $scope.choosedQuestions
      $scope.choosedQuestions.splice $scope.choosedQuestions.indexOf(question._id), 1
    console.log $scope.choosedQuestions, Research.questions

  $scope.tempList = $scope.questions
  $scope.showChoosed = ->
    if $scope.onlyShowChoosed
      $scope.tempList = $scope.questions
      all = $scope.choosedQuestions.concat()
      details = []
      if gotQuestions
        gotQuestions.forEach (question) ->
          qIndex = all.indexOf question._id
          if  qIndex != -1
            question.index = $scope.choosedQuestions.indexOf question._id
            details.push question
            all.splice qIndex, 1
        if !all.length
          $scope.questions = details
        else
          $http.post('/question/list', all).success (result) ->
            if result.status
              result.results.forEach (question) ->
                question.choosed = true
                details.push question
              $scope.questions = details
            else
              $scope.$emit 'error', result.error
      else
        $scope.questions = []
    else
      $scope.questions = $scope.tempList

  $scope.questionGrid =
    data:'questions'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    columnDefs:[
      {field: "title", displayName:"标题", cellTemplate: textCellTemplate}
      {field: "type", displayName:"类型", width:48, cellTemplate: questionTypeTemplate}
      {field: "image", displayName:"配图", width:45, cellTemplate: imgCellTemplate}
      {field: "creator.username", width:88, displayName:"创建者", cellTemplate: textCellTemplate}
      {field: "created_at", width:100, displayName:"创建时间", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "排序选题", width:100,cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
      <div class="col-md-8 col-md-offset-2" style="margin-top: 2px;">
          <input type="number" style="width: 40px" tooltip-append-to-body="true" ng-model="row.entity.index"
            tooltip="排序" ng-show="onlyShowChoosed" ng-hide="!onlyShowChoosed">
          <input type="checkbox" style="margin-top: 7px" ng-checked="row.entity.choosed" tooltip="选题" tooltip-append-to-body="true" ng-model="row.entity.choosed" ng-change="checked(row.entity)"> </div>
      </div>'}
    ]

research.controller 'Step3Ctrl', ($scope, $http, Research) ->
  $scope.Research = Research

  listUri = '/user/list'
  configScopeForNgGrid $scope

  gotUsers = undefined #所有从后台获取的用户详情数组
  Research.users = [] unless Research.users
  $scope.choosedUsers = Research.users #所有选中的问题ID数组

  $scope.search = ->
    $scope.page = 1
    $scope.users = null
    $scope.getList()

  $scope.getList = ->
    $http.get(listUri, params:username:$scope.searchText,page:$scope.page,perPage:20).success (result) ->
      if(result.status)
        if !$scope.users
          $scope.users = result.results
          unless gotUsers
            gotUsers = $scope.users.concat()
            Research.gotUsers = gotUsers
          $scope.judgeQeustionIfChoosed()
        else if result.results and result.results.length
          result.results.forEach (item)->
            $scope.users.push item
          $scope.judgeQeustionIfChoosed()
        else
          $scope.page -= 1
          $scope.$emit 'error', '没有更多的数据了'
      else
        $scope.$emit 'error', result.error

  $scope.getList()

  $scope.page = 1

  $scope.$on 'ngGridEventScroll', ->
    $scope.page++
    $scope.getList()

  $scope.judgeQeustionIfChoosed = ->
    if $scope.users and $scope.choosedUsers
      $scope.users.forEach (user) ->
        user.choosed = $scope.choosedUsers.indexOf(user._id) != -1
        gotUsers.push user if gotUsers.indexOf user == -1

  $scope.checked = (user) ->
    if user.choosed
      $scope.choosedUsers.push user._id
    else if $scope.choosedUsers
      $scope.choosedUsers.splice $scope.choosedUsers.indexOf(user._id), 1

  $scope.tempList = $scope.users
  $scope.onlyShowChoosed = false
  $scope.showChoosed = ->
    $scope.onlyShowChoosed = !$scope.onlyShowChoosed
    if $scope.onlyShowChoosed
      $scope.tempList = $scope.users
      all = $scope.choosedUsers.concat()
      details = []
      if gotUsers
        gotUsers.forEach (question) ->
          qIndex = all.indexOf question._id
          if  qIndex != -1
            question.index = details.length+1 if !question.index
            details.push question
            all.splice qIndex, 1
        if !all.length
          $scope.users = details
        else
          $http.post('/user/list', all).success (result) ->
            if result.status
              result.results.forEach (question) ->
                question.choosed = true
                details.push question
              $scope.users = details
            else
              $scope.$emit 'error', result.error
      else
        $scope.users = []
    else
      $scope.users = $scope.tempList

  $scope.dataGrid =
    data:'users'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    columnDefs:[
      {field: "username", displayName:"用户名", cellTemplate: textCellTemplate}
      {field: "mobile", displayName:"手机号", width:115, cellTemplate: textCellTemplate}
      {field: "email", displayName:"邮箱", cellTemplate: textCellTemplate}
      {field: "creator.username", width:88, displayName:"创建者", cellTemplate: textCellTemplate}
      {field: "created_at", width:100, displayName:"创建时间", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "选中", width:50, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
            <div class="col-md-8 col-md-offset-2" style="margin-top: 2px;">
                <input type="checkbox" style="margin-top: 7px" ng-checked="row.entity.choosed" tooltip="选人" tooltip-append-to-body="true" ng-model="row.entity.choosed" ng-change="checked(row.entity)"> </div>
            </div>'}
    ]

ModalInstanceCtrl = ($scope, $modalInstance, http, route, Research, location, isRebuild) ->

  $scope.$on 'error', (event, args) ->
    $scope.msg = args

  $scope.step = 0
  $scope.isActive = (step) ->
    return step == $scope.step

  $scope.getLabel = ->
    if $scope.step != 2
      return '下一步'
    else
      return '完成'

  $scope.pre = ->
    $scope.step -= 1 if $scope.step > 0
    $scope.changeStep()

  $scope.changeStep = ->
    if $scope.step == 1
      location.path '/step2'
    else if $scope.step == 2
      location.path '/step3'
    else if $scope.step == 0
      location.path '/'
    else
      $scope.ok()
    $scope.showPre = $scope.step != 0

  $scope.next = ->
    if $scope.step == 0
      msg = '研究名称不能为空' unless Research.name
      return $scope.msg = msg if msg
    else if $scope.step == 1
      if Research.questions and Research.gotQuestions
        arr = []
        Research.gotQuestions.sort (a, b) ->
          return a.index - b.index
        console.log Research.questions, Research.gotQuestions.length
        i = 0
        while i < Research.gotQuestions.length
          q = Research.gotQuestions[i]
          if Research.questions.indexOf(q._id) != -1 and arr.indexOf(q._id) == -1
              arr.push q._id
          i++
        Research.questions = arr
        delete Research['gotQuestions']
      console.log Research.questions
    else if $scope.step == 2
      $scope.ok()
    $scope.msg = ''
    $scope.step += 1 if $scope.step <2
    $scope.changeStep()

  $scope.buttonDisabled = false

  if Research._id and !isRebuild
    $scope.update = true
    $scope.title = '编辑研究'
  else
    $scope.title = '新建研究'

  $scope.change = (u) ->
    $scope.user_pro = u

  $scope.addImage = ->
    return

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.select = (value) ->
    $scope.selectedType = value;
    return

  $scope.ok = ->
    $scope.buttonDisabled = true
    delete Research['gotUsers']
    console.log Research
    tags = []
    if Research.tags
      Research.tags.forEach (tag)->
        if typeof tag == 'string'
          tags.push(tag)
        else
          tags.push(tag.text)
    Research.tags = tags
    console.log Research.tags
    if $scope.update
      http.post('/research/update', Research).success((result) ->
        if result.status
          $modalInstance.close 'refresh'
        else
          $scope.msg = result.results
          $scope.buttonDisabled = false).error (error) ->
            $scope.msg = '出错了，请稍后再试'
            $scope.buttonDisabled = false
    else
      http.post('/research/add', Research).success((result) ->
        if result.status
          $modalInstance.close result.results
        else
          $scope.msg = result.results
          $scope.buttonDisabled = false).error (error) ->
            $scope.msg = '出错了，请稍后再试'
            $scope.buttonDisabled = false
    return


  return

angular.bootstrap document.getElementById("researchDiv"), ['ResearchApp']