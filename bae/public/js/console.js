// Generated by CoffeeScript 1.7.1
(function() {
  var cs;

  cs = angular.module('ConsoleApp', ['ui.bootstrap']);

  cs.controller('ConsoleCtrl', function($scope, $http, $timeout, $interval) {
    var data, domMain, echarts, fileLocation, getData, getLogs, getNow, getRealtime, legends, myChart, now, option, refresh;
    $http.get('/sms/left').success(function(result) {
      return $scope.smsLeft = result.result;
    });
    $scope.status = '1';
    getData = function() {};
    data = null;
    legends = null;
    option = null;
    now = null;
    getNow = function() {
      return $http.get('/now').success(function(result) {
        return now = new Date(result);
      });
    };
    getNow();
    getLogs = function() {
      return $http.get('/logs').success(function(result) {
        var arr, datas, i, o, series;
        legends = ["在线时长(分钟)", "DM播放(次数)", "消息接收(次数)", "消息确认(次数)"];
        option = {
          tooltip: {
            trigger: "axis",
            axisPointer: {
              type: "shadow"
            }
          },
          legend: {
            data: legends
          },
          toolbox: {
            show: true,
            feature: {
              mark: {
                show: false
              },
              dataView: {
                show: false,
                readOnly: false
              },
              magicType: {
                show: false
              },
              restore: {
                show: false
              },
              saveAsImage: {
                show: true
              }
            }
          },
          calculable: true,
          xAxis: [
            {
              type: "value"
            }
          ],
          yAxis: [
            {
              type: "category"
            }
          ]
        };
        if (result.status) {
          data = result.results;
          arr = [];
          series = [];
          datas = [];
          if (data) {
            data.forEach(function(d) {
              var i, _results;
              arr.push(d.username);
              i = 0;
              _results = [];
              while (i < legends.length) {
                if (!datas[i]) {
                  datas[i] = [];
                }
                switch (i) {
                  case 0:
                    datas[i].push(d.count);
                    break;
                  case 1:
                    datas[i].push(d.dm);
                    break;
                  case 2:
                    datas[i].push(d.received);
                    break;
                  case 3:
                    datas[i].push(d.confirmed);
                }
                _results.push(i++);
              }
              return _results;
            });
          }
          i = 0;
          while (i < legends.length) {
            o = {
              type: "bar",
              stack: "总量",
              itemStyle: {
                normal: {
                  label: {
                    show: true,
                    position: "inside"
                  }
                }
              }
            };
            o.name = legends[i];
            o.data = datas[i];
            series.push(o);
            i++;
          }
          option.yAxis[0].data = arr;
          option.series = series;
          return refresh();
        } else {
          return confirm(1, '获取统计数据失败', result.results);
        }
      });
    };
    getRealtime = function() {
      return $http.get('/realtime').success(function(result) {
        var arr1, arr2, geos;
        arr1 = [];
        arr2 = [];
        geos = {};
        if (result.status) {
          data = result.result;
          console.log(data);
          if (!now) {
            now = moment();
          }
          data.forEach(function(o) {
            var value;
            value = 999;
            if (o.updated_at) {
              data = now.valueOf() - new Date(o.updated_at).valueOf();
              value = moment(data).minute();
              arr1.push({
                name: o.username,
                value: value
              });
            } else {
              arr1.push({
                name: o.username,
                value: value
              });
            }
            if (value > 500) {
              arr2.push({
                name: o.username,
                value: value
              });
            }
            if (o.geo) {
              return geos[o.username] = [o.geo.lng, o.geo.lat];
            }
          });
        } else {
          showAlert('获取实时监控数据失败');
        }
        option = {
          title: {
            text: '集团公播实时监控',
            subtext: '每分钟更新状态',
            x: 'center'
          },
          tooltip: {
            trigger: 'item'
          },
          legend: {
            orient: 'vertical',
            x: 'left',
            data: ['离线时长']
          },
          dataRange: {
            min: 0,
            max: 60,
            calculable: false,
            color: ['red', 'green']
          },
          toolbox: {
            show: true,
            orient: 'vertical',
            x: 'right',
            y: 'center'
          },
          feature: {
            saveAsImage: {
              show: true
            }
          },
          series: [
            {
              name: '离线时长(分钟)',
              type: 'map',
              mapType: 'china',
              hoverable: false,
              roam: true,
              scaleLimit: {
                min: 0.5,
                max: 2
              },
              data: arr2,
              markPoint: {
                symbolSize: 5,
                itemStyle: {
                  normal: {
                    borderColor: '#87cefa',
                    borderWidth: 0,
                    label: {
                      show: false
                    }
                  },
                  emphasis: {
                    borderColor: '#1e90ff',
                    borderWidth: 0,
                    label: {
                      show: false
                    }
                  }
                },
                data: arr1
              },
              geoCoord: geos
            }, {
              name: '离线时长',
              type: 'map',
              mapType: 'china',
              data: [],
              markPoint: {
                symbol: "emptyCircle",
                symbolSize: function(v) {
                  return 10 + v / 100;
                },
                effect: {
                  show: true,
                  shadowBlur: 0
                },
                itemStyle: {
                  normal: {
                    label: {
                      show: false
                    }
                  }
                },
                data: arr2
              }
            }
          ]
        };
        return refresh();
      });
    };
    refresh = function() {
      var myChart;
      if (myChart && myChart.dispose) {
        myChart.dispose();
      }
      myChart = echarts.init(domMain);
      window.onresize = myChart.resize;
      return myChart.setOption(option, true);
    };
    $interval(function() {
      if ($scope.status === '1') {
        console.log('run');
        return getRealtime();
      }
    }, 60000);
    $interval(getNow, 50000);
    domMain = document.getElementById('main');
    myChart = null;
    echarts = null;
    fileLocation = './components/echart/www/js/echarts-map';
    require.config({
      paths: {
        echarts: fileLocation,
        'echarts/chart/pie': fileLocation,
        'echarts/chart/map': fileLocation
      }
    });
    return require(['echarts', 'echarts/chart/pie', 'echarts/chart/map'], function(ec) {
      echarts = ec;
      if (myChart && myChart.dispose) {
        myChart.dispose();
      }
      return $scope.$watch('status', function() {
        if ($scope.status !== '1') {
          return getLogs();
        } else {
          return $timeout(getRealtime, 100);
        }
      });
    });
  });

  angular.element(document).ready(function() {
    return angular.bootstrap(document.getElementById("consoleDiv"), ['ConsoleApp']);
  });

}).call(this);

//# sourceMappingURL=console.map
