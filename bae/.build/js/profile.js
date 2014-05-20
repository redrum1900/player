/**
 * Created by mani on 14-3-25.
 */

var datagrid = angular.module('MM', ['ngGrid', 'ui.bootstrap']);
datagrid.controller('MMCtrl', function ($scope, $http, $modal, $log) {

    $scope.pass = function (data) {

        data.approved = true;
        data.handled = true;
        $http.post('/apply/handler', data).success(function (result) {
            if (result.status) {
                $scope.getManagers();
            } else {
                $scope.data = '操作申请失败';
                $scope.content = result.results;
                $scope.open();
            }
        });

    };

    $scope.deny = function (data) {
        data.approved = false;
        data.handled = true;
        $http.post('/apply/handler', data).success(function (result) {
            if (result.status) {
            } else {
                $scope.data = '操作申请失败';
                $scope.content = result.results;
                $scope.open();
            }
        });
    };

    $scope.getApplies = function () {
        $http.get('/apply/list').success(function (result) {

            if (result.status) {
                $scope.applies = result.results;
            } else {
                $scope.data = '获取申请列表失败';
                $scope.content = result.results;
                $scope.open();
            }
        });
    }

    $scope.getApplies();

    $scope.getManagers = function () {
        $http.get('/manager/list').success(function (result) {

            if (result.status) {
                $scope.managers = result.results;
            } else {
                $scope.data = '获取管理员列表失败';
                $scope.content = result.results;
                $scope.open();
            }
        });
    }

    $scope.getManagers();

    $scope.open = function () {

        var modalInstance = $modal.open({
            templateUrl: 'modal.html',
            controller: ModalInstanceCtrl,
            resolve: {
                title: function () {
                    return $scope.data
                },
                content: function () {
                    return $scope.content
                }
            }
        });

    }

    $scope.appliesGrid = {
        data: 'applies',
        multiSelect: false,
        enableRowSelection: false,
        rowHeight: 40,
        enableSorting: false,
        columnDefs: [
            {field: "username", displayName: "用户名", cellTemplate: textCellTemplate},
            {field: "email", displayName: "邮箱", cellTemplate: textCellTemplate},
            {field: "approved", displayName: "是否通过", cellTemplate: textCellTemplate},
            {field: "handler", displayName: "操作",
                cellTemplate: '<div class="row" ng-style="{height: rowHeight}">' +
                    '<div class="col-md-4 col-md-offset-4" style="padding: 0px; display: inline-block; vertical-align: middle; margin-top: 8px">' +
                    '<a class="btn btn-primary btn-xs col-md-5" ng-hide="row.getProperty(\'handled\')" ng-click="pass(row.entity)">通过</a>' +
                    '<a class="btn btn-primary btn-xs col-md-5 col-md-offset-2" ng-hide="row.getProperty(\'handled\')" ng-click="deny(row.entity)">拒绝</a>' +
                    '</div></div>'}
        ]
    };

    $scope.isDisabled = function (value) {
        return value ? '启用' : '禁用';
    };

    $scope.getButtonStyle = function (value) {
        return value ? 'btn-success' : 'btn-warning';
    }

    $scope.disable = function (data) {
        data = data.entity;
        data.disabled = !data.disabled;
        $http.post('/manager/update', data, function (result) {
            if (result.status) {

            } else {
                $scope.title = '操作管理员失败';
                $scope.content = result.results;
                $scope.open();
                data.disabled = !data.disabled;
            }
        });
    }

    $log.log(textCellTemplate);

    $scope.managersGrid = {
        data: 'managers',
        multiSelect: false,
        enableRowSelection: false,
        enableSorting: false,
        columnDefs: [
            {field: "username", displayName: "用户名"},
            {field: "email", displayName: "邮箱"},
            {field: "signed_in_times", displayName: "登录次数"},
            {field: "disabled", displayName: "是否已禁用"},
            {field: "handler", displayName: "操作",
                cellTemplate: '<div class="row" ng-style="{height: rowHeight}">' +
                    '<div class="col-md-2 col-md-offset-5" ng-style="{height: rowHeight}" style="padding-left: 0;padding-right: 0">' +
                    '<a class="btn btn-xs" style=" margin-top: 3px; " ng-class="getButtonStyle(row.getProperty(\'disabled\'))" ng-click="disable(row)">{{isDisabled(row.getProperty("disabled"))}}</a>' +
                    '</div></div>'}
        ]
    };
})

angular.bootstrap(document.getElementById("MMDiv"), ['MM']);

var ModalInstanceCtrl = function ($scope, $modalInstance, title, content) {
    $scope.title = title;
    $scope.content = content;
    $scope.ok = function () {
        $modalInstance.close();
    }
}