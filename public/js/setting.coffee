setting = angular.module('SettingApp', ['ngTagsInput', 'ui.bootstrap'])
setting.controller 'ProgressDemoCtrl', ($scope) ->

setting.controller 'SettingCtrl', ($scope, $http) ->

  $scope.getTags = (key, callback, subKey, valuePro) ->
    getDict $http, key, (result) ->
      if subKey
        if result and valuePro
          $scope[subKey][key] = result[valuePro]
        else
          $scope[subKey][key] = result
      else
        $scope[key] = result
      callback result if result and callback
    return

  $scope.updateTags = (key, list, callback, isPro) ->
    if(isPro)
      data = key:key, list:list
    else
      data = list
    data.key = key
    arr = []
    data.list.forEach (text) ->
      arr.push text.text
    data.list = arr
    $scope.handling = true
    console.log data
    $http.post '/dict/update/list', data
      .success (result) ->
        $scope.handling = false
        if result.status
          callback true
        else
          showAlert result.error
    return

  updateResult = (result) ->
    showAlert result.error unless result.status

  $scope.tagAdded = (key) ->
    $scope.updateTags key, $scope[key], updateResult
  $scope.tagRemoved = (key) ->
    $scope.updateTags key, $scope[key], updateResult

  $scope.getTags 'SongTags'
  $scope.getTags 'MenuTags'
  $scope.getTags 'ClientTags'
#  #问题涉及的用户属性
#  $scope.getTags 'QUserPros'
#  #用户来源
#  $scope.getTags 'UserFrom'
#  #用户额外属性
#  $scope.Pros = {}s
#  $scope.proRemoved = (key) ->
#    $scope.updateTags key, $scope.Pros[key], updateResult, true
#  $scope.proAdded = (key) ->
#    $scope.updateTags key, $scope.Pros[key], updateResult, true
#  $scope.getTags 'UserExtraPro', (result) ->
#    if result and result.list and result.list.length
#      ((pro) ->
#        $scope.getTags pro, null, 'Pros', 'list'
#      ) pro for pro in result.list
#  #调查研究标签
#  $scope.getTags 'ResearchTags'

angular.bootstrap document.getElementById("settingDiv"), ['SettingApp']