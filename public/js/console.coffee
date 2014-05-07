cs = angular.module 'ConsoleApp', ['nvd3ChartDirectives']
cs.controller 'ConsoleCtrl', ($scope, $http)->

  $scope.data = ["key":"提交报告数","values": [
    [ 1, 0] ,
    [ 2, 10] ,
    [ 3, 120] ,
    [ 4, 130] ,
    [ 5, 140] ,
    [ 6, 1000] ,
    [ 7, 160] ,
    [ 8, 170] ,
    [ 9, 500] ,
    [ 12 , 1500] ,
    [ 13 , 3000]
  ]]

  $http.get('/sms/left').success (result)->
    console.log result
    $scope.smsLeft = result.result

#  $scope.toolTipContentFunction = ->
#    (key, x, y, e, graph) ->
#      x+':'+y

#  $scope.xAxisTickFormatFunction = ->
#    (key, x, y, e, graph) ->
#      x+':'+y

#  $scope.yAxisTickFormatFunction = ->
#    (key, x, y, e, graph) ->
#      x+':'+y

#  $scope.exampleData = [
#    {
#      "key": "Github Api Mean Web Response Time",
#      "values": [[1378387200.0, 123.08370666666667], [1378387500.0, 119.64371999999999], [1378387800.0, 126.92131333333332], [1378388100.0, 122.06958666666667], [1378388400.0, 126.50453], [1378388700.0, 168.14301666666668], [1378389000.0, 132.83243], [1378389300.0, 137.11919333333336], [1378389600.0, 152.85155], [1378389900.0, 133.26816], [1378390200.0, 178.5094466666667], [1378390500.0, 156.0947666666667]]
#    }];
#
#  $scope.xAxisTickValuesFunction = ->
#    (d)->
#      tickVals = [];
#      values = d[0].values;
#      interestedTimeValuesArray = [0, 00, 15, 30, 45];
#      ((v)->
#        if(interestedTimeValuesArray.indexOf(moment.unix(v[0]).minute()) >= 0)
#          tickVals.push(values[i][0])
#      ) value for value in values
#      console.log('xAxisTickValuesFunction', d);
#      return tickVals;
#
#  $scope.xAxisTickFormatFunction = ->
#    (d)->
#      d3.time.format('%H:%M')(moment.unix(d).toDate());

angular.element(document).ready ->
  angular.bootstrap(document.getElementById("consoleDiv"), ['ConsoleApp'])