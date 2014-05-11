/**
 * Created by mani on 14-3-27.
 */
var textCellTemplate = '<div class="ngCellText" style="padding: 0px; padding-left: 10px;" ng-class="col.colIndex()">' +
    '<span ng-cell-text style="line-height:{{rowHeight}}px">{{row.getProperty(col.field)}}</span></div>';

var questionTypeTemplate = '<div class="ngCellText" style="padding: 0px; padding-left: 10px;" ng-class="col.colIndex()">' +
    '<span ng-cell-text style="line-height:{{rowHeight}}px">{{getQuestionType(row.getProperty(col.field))}}</span></div>';

var dateCellTemplate = '<div class="ngCellText" style="padding: 0px; padding-left: 10px;" ng-class="col.colIndex()">' +
    '<span tooltip-append-to-body="true" tooltip="{{getDateDetail(row.getProperty(col.field))}}" ng-cell-text style="line-height:{{rowHeight}}px">{{getDate(row.getProperty(col.field))}}</span></div>';

var imgCellTemplate = '<img style="width: 30px; height: 30px; margin-left: 7px;margin-top: 5px" ng-if="row.getProperty(col.field)" class="img-rounded" ng-src="{{ row.getProperty(col.field) }}">'

var configScopeForNgGrid = function($scope){

    $scope.getDateDetail = function(date){
        return date ? moment(new Date(date)).format('YYYY-MM-DD H:m:s') : '';
    }

    $scope.getDate = function(date){
        return date ? moment(new Date(date)).format('YYYY-MM-DD') : '';
    }

    $scope.isDisabled = function(value){
        return value ? '启用' : '禁用';
    }

    $scope.getButtonStyle = function(value){
        return value ? 'btn-success' : 'btn-warning';
    }
}

var researchStatusTemplate = '<div class="ngCellText" style="padding: 0px; padding-left: 10px;" ng-class="col.colIndex()">' +
    '<span ng-cell-text style="line-height:{{rowHeight}}px">{{getResearchStatus(row.entity)}}</span></div>';

var configScopeForResearchStatus = function ($scope) {
    $scope.statuses = [
        {label: '未开始', value: 1},
        {label: '进行中', value: 2},
        {label: '已结束', value: 3}
    ];
    $scope.getResearchStatus = function(status){
        var label;
        console.log(status);
        return;
        $scope.statuses.forEach(function (object) {
            if (object.value == status) {
                label = object.label;
                return label;
            }
        });
        return label;
    }
};

var configScopeForQuestionType = function($scope) {
    $scope.types = [
        {label: '多选', value: 1},
        {label: '单选', value: 2},
        {label: '排序', value: 3},
        {label: '评分', value: 4},
        {label: '输入', value: 5}
    ];
    $scope.getQuestionType = function(type){
        var label;
        $scope.types.forEach(function (object) {
            if(object.value == type){
                label = object.label;
                return;
            }
        });
        return label;
    }
};