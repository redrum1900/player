songs = angular.module 'SongApp', ['ngGrid', 'ngRoute', 'ngTagsInput', 'ui.bootstrap']
songs.controller 'SongCtrl', ($scope, $http, $modal, $q, $filter,$window, $timeout) ->

  listUri = '/song/list'
  updateStatusUri = '/song/update/status'
  configScopeForNgGrid $scope

  $scope.module = 'templates/html/song/home.html'

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
    if !data.disabled
      confirm 2, '媒资状态更新', '是否确认禁用该媒资，一旦禁用后创建歌单时将不能再选中该媒资', (value)->
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
      {field: "name", displayName:"名称", cellTemplate: textCellTemplate}
      {field: "tags", displayName:"标签", cellTemplate: textCellTemplate}
      {field: "artist", displayName:"歌手", cellTemplate: textCellTemplate}
      {field: "album", displayName:"专辑", cellTemplate: textCellTemplate}
      {field: "published_at", width:96, displayName:"发行时间", cellTemplate: textCellTemplate}
      {field: "right_date", width:96, displayName:"版权到期", cellTemplate: dateCellTemplate}
      {field: "handler", displayName: "操作", width:150, cellTemplate: '<div class="row" ng-style="{height: rowHeight}">
      <div class="col-md-12 text-center" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">
        <a class="btn btn-default btn-xs" ng-click="try(row.entity)">试听</a>
        <a class="btn btn-primary btn-xs" ng-click="edit(row.entity)">编辑</a>
        <a class="btn btn-xs" ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="updateStatus(row.entity)" ng-disabled="updating">{{ isDisabled(row.getProperty("disabled")) }}</a></div></div>'}
    ]
  $scope.try = (data)->
    $window.open(imgHost+data.url+'?p/1/avthumb/mp3/ab/64k')
    return true

  $scope.edit = (data) ->
    $scope.data = data
    $scope.open()

  $scope.multiGrid =
    data:'tobeUploadedFiles'
    multiSelect:false
    enableRowSelection:false
    enableSorting:false
    enableHighlighting:true
    rowHeight:40
    columnDefs:[
      {field: "name", displayName:"名称", cellTemplate: textCellTemplate}
      {field: "duration", displayName:"时长", cellTemplate: textCellTemplate}
      {field: "tags", displayName:"标签", cellTemplate: textCellTemplate}
      {field: "artist", displayName:"歌手", cellTemplate: textCellTemplate}
      {field: "album", displayName:"专辑", cellTemplate: textCellTemplate}
      {field: "published_at", width:96, displayName:"发行时间", cellTemplate: textCellTemplate}
      {field: "right_date", width:96, displayName:"版权到期", cellTemplate: dateCellTemplate}
      {field: "percent", width:60, displayName:"进度", cellTemplate: textCellTemplate}
    ]

  data = ''
  choosedFiles = ''
  objectUrl = ''
  parseIndex = 0
  done = 2
  fileDic = {}
  $("#audio2").on "canplaythrough", (e)->
    data.duration = e.currentTarget.duration
    URL.revokeObjectURL(objectUrl);
    done++
    $scope.$apply ->
      parseFiles()

  parseFiles = ->
    if done == 2 && data
        $scope.tobeUploadedFiles.push data
    if parseIndex == choosedFiles.length || done != 2
      if parseIndex == choosedFiles.length && done == 2
        console.log $scope.tobeUploadedFiles.length, 'ok', parseIndex, choosedFiles.length, done
      return
    done = 0
    data = {}
    file = choosedFiles[parseIndex]
    fileDic[file.name] = data
    parseIndex++
    File = file.getSource().getSource()
    objectUrl = URL.createObjectURL(File)
    $("#audio2").prop("src", objectUrl)
    ID3.loadTags file.name, ->
      tags = ID3.getAllTags(file.name)
      data.name = tags.title
      data.artist = tags.artist
      data.album = tags.album
      data.published_at = tags.year
      data.size = file.size
      comment = tags.comment.text if tags.comment
      if comment
        arr = comment.split '|'
        arr.forEach (o)->
          a2 = o.split '='
          if a2.length == 2
            key = a2[0]
            value = a2[1]
            switch key
              when 'c'
                data.company = value
              when 't'
                data.tags = value.split ','
              when 'ci'
                data.writer = value
              when 'qu'
                data.composer = value
              when 'r'
                data.right_date = value
      done++
      $scope.$apply ->
        parseFiles()
    ,
      {tags: ["artist", "title", "album", "year", "comment", "track", "genre", "lyrics", "picture"],dataReader: FileAPIReader(File)}

  $scope.tobeUploadedFiles = []

  $scope.startUpload = ->
    if choosedFiles && choosedFiles.length
      $scope.buttonDisabled = true
      uploader.start()

  uploader = ''
  uploaded = 0

  $scope.addMulti = ->
    $scope.module = 'templates/html/song/multi.html'
    $timeout(->
      uploader = Qiniu.uploader(
        runtimes: 'html5,flash,html4'
        browse_button: 'p11'
        uptoken_url:'/upload/token/mp3'
        unique_names:true
        max_retries: 3
        chunk_size: '4mb'
        filters:
          mime_types:[title:'mp3媒资', extensions:'mp3']
        unique_names: true
        domain: imgHost
        container: 'c11'
        max_file_size: '100mb'
        flash_swf_url: 'js/plupload/Moxie.swf'
        max_retries: 1
        auto_start: false
        init:
          'FilesAdded': (up, files)->
            if choosedFiles && choosedFiles.length
              choosedFiles.forEach (file)->
                uploader.removeFile file
            console.log 'cf', files.length, choosedFiles
            choosedFiles = files
            temp = {}
            has = false
            files.forEach (file)->
              if temp[file.name]
                confirm(1,'出错','上传文件名称不能存在相同的')
                has = true
                return
              else
                temp[file.name] = true
            if !has
              $scope.$apply ->
                data = ''
                parseIndex = 0
                uploaded = 0
                $scope.tobeUploadedFiles.length = 0
                parseFiles()
                $scope.msg = '选择了 '+choosedFiles.length+' 文件'
          'UploadComplete':->
            $scope.$apply ->
              $scope.buttonDisabled = false
              choosedFiles = null
              console.log 'all uploaded'
              $scope.msg = '全部上传完毕，共计'+uploaded
          'FileUploaded':(up, file, info)->
            data = fileDic[file.name]
            info = angular.fromJson info
            $scope.$apply ->
              data.url = info.key
              console.log 'uploaded', file.name, data
              postSong data
          'UploadProgress':(up,file)->
            console.log 'uploading',file.name,file.percent
            data = fileDic[file.name]
            $scope.$apply ->
              data.percent = file.percent+'%'
          'Error':(up, err, errTip)->
            $scope.msg = err
            $scope.buttonDisabled = false
      )
    , 500)

  postSong = (data)->
    $http.post('/song/add', data).success((result) ->
      if !result.status
        confirm(1, '添加到服务器出错', result.error)
        $scope.buttonDisabled = false
        $scope.msg = '点击开始再试试'
        uploader.stop()
      else
        uploaded++
        $scope.msg = '已上传 '+uploaded+'/'+parseIndex+' '
    ).error (error) ->
      confirm(1, '添加到服务器出错', result.error)
      $scope.buttonDisabled = false
      $scope.msg = '点击开始再试试'
      uploader.stop()

  $scope.back = ->
    $scope.module = 'templates/html/song/home.html'
    $scope.search();

  $scope.add = ->
    $scope.data = {}
    $scope.open()
    return

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

  $scope.data = angular.copy data
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

  mp3Uploaded = if data then false else true
  coverUplaoded = if data then true else true

  objectUrl = ''

  $("#audio").on "canplaythrough", (e)->
    $scope.data.duration = e.currentTarget.duration
    console.log $scope.data.duration
    URL.revokeObjectURL(objectUrl);

  $timeout(->
    uploader = Qiniu.uploader(
      runtimes: 'html5,flash,html4'
      browse_button: 'p1'
      uptoken_url:'/upload/token/mp3'
      prevent_duplicates:true
      filters:
        mime_types:[title:'mp3媒资', extensions:'mp3']
      unique_names: true
      domain: imgHost
      container: 'c1'
      max_file_size: '100mb'
      flash_swf_url: 'js/plupload/Moxie.swf'
      max_retries: 1
      auto_start: true
      init:
        'FilesAdded': (up, files)->
          file = files[0]
          $scope.buttonDisabled = true
          data = $scope.data
          File = file.getSource().getSource()
          objectUrl = URL.createObjectURL(File)
          $("#audio").prop("src", objectUrl)
          ID3.loadTags file.name, ->
              tags = ID3.getAllTags(file.name)
              console.log(tags)
              data.name = tags.title
              data.artist = tags.artist
              data.album = tags.album
              data.published_at = tags.year
              data.size = file.size
              comment = tags.comment.text if tags.comment
              if comment
                arr = comment.split '|'
                arr.forEach (o)->
                  a2 = o.split '='
                  if a2.length == 2
                    key = a2[0]
                    value = a2[1]
                    switch key
                      when 'c'
                        data.company = value
                      when 't'
                        data.tags = value.split ','
                      when 'ci'
                        data.writer = value
                      when 'qu'
                        data.composer = value
                      when 'r'
                        data.right_date = value
            ,
              {tags: ["artist", "title", "album", "year", "comment", "track", "genre", "lyrics", "picture"],dataReader: FileAPIReader(File)}
        'FileUploaded':(up, file, info)->
          data = angular.fromJson info
          console.log data
          $timeout(->
            $scope.data.url = data.key
            $scope.msg = '上传成功'
            $scope.percent = 0
            mp3Uploaded = true
            if coverUplaoded
              $scope.buttonDisabled = false
          , 500)
        'UploadProgress':(up,file)->
          $scope.$apply ->
            $scope.percent = file.percent
            $scope.msg = file.percent + "%"
          console.log file.percent
        'Error':(up, err, errTip)->
          $scope.msg = err
          $scope.buttonDisabled = false
    )

    $scope.imgProgress = '上传封面'

#    uploader2 = Qiniu.uploader(
#      runtimes: 'html5,flash,html4'
#      browse_button: 'p2'
#      uptoken_url:'/upload/token'
#      unique_names: true
#      domain: imgHost
#      container: 'c2'
#      max_file_size: '10mb'
#      flash_swf_url: 'js/plupload/Moxie.swf'
#      dragdrop:true
#      drop_element:'c2'
#      max_retries: 1
#      auto_start: true
#      init:
#        'BeforeUpload': (up, file)->
#          $scope.buttonDisabled = true
#        'FileUploaded':(up, file, info)->
#          data = angular.fromJson info
#          console.log data
#          $timeout(->
#            $scope.data.cover = data.key
#            $scope.cover = imgHost+$scope.data.cover+'?imageView2/1/w/200/h/200'
#            $scope.imgProgress = '上传封面'
#            coverUplaoded = true
#            if mp3Uploaded
#              $scope.buttonDisabled = false
#          , 500)
#        'UploadProgress':(up,file)->
#          $scope.imgProgress = file.percent + "%"
#        'Error':(up, err, errTip)->
#          $scope.msg = err
#          $scope.buttonDisabled = false
#    )
  , 500)

  $scope.cancel = ->
    $modalInstance.close()
    return

  $scope.ok = ->

    if !$scope.data.name
      msg = '媒资名称必填'
    else if !$scope.data.url
      msg = '媒资尚未上传'
#    else if !$scope.data.cover
#      msg = '媒资封面尚未添加'
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
            $modalInstance.close 'refresh'
          else
            $scope.msg = result.error
            $scope.buttonDisabled = false).error (error) ->
              $scope.msg = '出错了，请稍后再试'
              $scope.buttonDisabled = false
    return

  return

angular.element(document).ready ->
  angular.bootstrap document.getElementById("songDiv"), ['SongApp']