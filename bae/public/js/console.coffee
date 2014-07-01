cs = angular.module 'ConsoleApp', ['ui.bootstrap']
cs.controller 'ConsoleCtrl', ($scope, $http)->

  $http.get('/sms/left').success (result)->
    console.log result
    $scope.smsLeft = result.result

#  configDateForScope $scope
#  $scope.today = new Date()
#  $scope.begin_date = new Date().setDate($scope.today.getDate() - 30)
#  $scope.end_date = new Date()

#  $scope.$watch 'begin_date', ->
#    console.log $scope.begin_date
#    getData()
  $scope.status = '1'

  $scope.$watch 'status', ->
    console.log $scope.status
    if $scope.status != '1'
      getLogs()
    else
      getRealtime()
#    getData()

  getData = ->
#    $http.get('/analysis/report', params:type:$scope.status,from:$scope.begin_date,to:$scope.end_date).success((result)->
#      console.log result
#    ).error (err)->
#      console.log err

  data = null
  legends = null
  option = null

  getLogs = ->
    $http.get('/logs').success (result)->

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

  getRealtime = ->
    $http.get('/realtime').success (result)->

      arr1 = []
      arr2 = []
      geos = {}
      i = 0
      while i < 100
        v = Math.random()
        value = if v > 0.5 then 0 else Math.round(v*60)
        if value
          arr2.push name:name,value:value
        name = '门店'+i;
        arr1.push name:name,value:value
        geos[name] = [73+Math.random()*60, 21+Math.random()*30]
        i++

      arr2.sort (a,b)->
        return -a.value+b.value
      arr2 = [arr2[0], arr2[1], arr2[2]]

      option =
        title:
          text: '集团公播实时监控'
          subtext: '每10秒更新状态'
          x:'center'
        tooltip:
          trigger: 'item'
        legend:
          orient: 'vertical'
          x:'left'
          data:['离线时长']
        dataRange:
          min : 0
          max : 60
          calculable : false
          color: ['red','green']
        toolbox:
          show : true,
          orient : 'vertical'
          x: 'right'
          y: 'center'
        feature:
          saveAsImage : show: true
        series:[
          {
            name: '离线时长(分钟)'
            type: 'map'
            mapType: 'china'
            hoverable: false
            roam:true
            scaleLimit:min:0.5,max:2
            data : arr2
            markPoint :
              symbolSize: 5
              itemStyle:
                normal:
                  borderColor: '#87cefa'
                  borderWidth: 1
                  label:
                    show: false
                emphasis:
                  borderColor: '#1e90ff'
                  borderWidth: 0
                  label:
                    show: false
              data : arr1
            geoCoord:geos
          }
          {
            name: '离线时长'
            type: 'map'
            mapType: 'china'
            data:[]
            markPoint:
              symbol: "emptyCircle"
              symbolSize: (v) ->
                10 + v / 100

              effect:
                show: true
                shadowBlur: 0

              itemStyle:
                normal:
                  label:
                    show: false

              data: arr2
          }
        ]

      if result.status
        data = result.result
      else
        showAlert('获取实时监控数据失败')

      refresh()

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
  fileLocation = './components/echart/www/js/echarts-map'
  require.config
    paths:
      echarts: fileLocation
      'echarts/chart/pie': fileLocation
      'echarts/chart/map': fileLocation
  require ['echarts','echarts/chart/pie', 'echarts/chart/map'], (ec)->
    echarts = ec
    if myChart && myChart.dispose
      myChart.dispose()
    myChart = echarts.init(domMain)
    window.onresize = myChart.resize
    getRealtime()
#    getLogs()

angular.element(document).ready ->
  angular.bootstrap(document.getElementById("consoleDiv"), ['ConsoleApp'])