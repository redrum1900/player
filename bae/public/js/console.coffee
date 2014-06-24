cs = angular.module 'ConsoleApp', ['ui.bootstrap']
cs.controller 'ConsoleCtrl', ($scope, $http)->

  $http.get('/sms/left').success (result)->
    console.log result
    $scope.smsLeft = result.result

  configDateForScope $scope
  $scope.today = new Date()
  $scope.begin_date = new Date().setDate($scope.today.getDate() - 30)
  $scope.end_date = new Date()

  $scope.$watch 'begin_date', ->
    console.log $scope.begin_date
    getData()

  $scope.$watch 'status', ->
    console.log $scope.status
    getData()

  getData = ->
#    $http.get('/analysis/report', params:type:$scope.status,from:$scope.begin_date,to:$scope.end_date).success((result)->
#      console.log result
#    ).error (err)->
#      console.log err

  data = null

  getLogs = ->
    $http.get('/logs').success (result)->
      if result.status
        data = result.results
        arr = []
        series = []
        datas = []
        if data
          data.forEach (d)->
            arr.push d.username
            i = 0
            while i<legends.length
              datas[i] = [] unless datas[i]
              switch i
                when 0
                  datas[i].push d.count
                when 1
                  datas[i].push d.dm
                when 2
                  datas[i].push d.received
                when 3
                  datas[i].push d.confirmed
              i++
        i = 0
        while i<legends.length
          o =
            type: "bar"
            stack: "总量"
            itemStyle:
              normal:
                label:
                  show: true
                  position: "inside"
          o.name = legends[i]
          o.data = datas[i]
          series.push o
          i++

        option.yAxis[0].data = arr
        option.series = series
        refresh()

      else
        confirm(1,'获取统计数据失败',result.results)

  legends =  [
    "在线时长(分钟)"
    "DM播放(次数)"
    "消息接收(次数)"
    "消息确认(次数)"
  ]

  option =
    tooltip:
      trigger: "axis"
      axisPointer: # 坐标轴指示器，坐标轴触发有效
        type: "shadow" # 默认为直线，可选为：'line' | 'shadow'

    legend:
      data: legends

    toolbox:
      show: true
      feature:
        mark:
          show: false

        dataView:
          show: false
          readOnly: false

        magicType:
          show: false

        restore:
          show: false

        saveAsImage:
          show: true

    calculable: true
    xAxis: [type: "value"]
    yAxis: [
      type: "category"
    ]

  refresh = ->
    if myChart && myChart.dispose
      myChart.dispose()
    myChart = echarts.init(domMain)
    window.onresize = myChart.resize
    console.log option
    myChart.setOption option, true

  domMain = document.getElementById 'main'
  myChart = null
  echarts = null
  fileLocation = './components/echart/www/js/echarts'
  require.config paths:echarts: fileLocation,'echarts/chart/pie': fileLocation
  require ['echarts','echarts/chart/pie'], (ec)->
    echarts = ec
    if myChart && myChart.dispose
      myChart.dispose()
    myChart = echarts.init(domMain)
    window.onresize = myChart.resize
    getLogs()

angular.element(document).ready ->
  angular.bootstrap(document.getElementById("consoleDiv"), ['ConsoleApp'])