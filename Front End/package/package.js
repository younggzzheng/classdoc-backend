'use strict';

angular.module('myApp.package', ['ngRoute'])

.config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/package', {
    templateUrl: 'package/package.html',
    controller: 'PackageCtrl'
  });
}])
// Controller for Table of Contents
.controller('PackageCtrl', ['$scope', '$sce', '$compile', '$window', '$document', '$rootScope', '$http', 'packageFactory', function($scope, $sce, $compile, $window, $document, $rootScope, $http, packageFactory) {

}])

// Factory for classes
.factory('packageFactory',['$http','$rootScope', function($http, $rootScope) {
  return {};
}]);
