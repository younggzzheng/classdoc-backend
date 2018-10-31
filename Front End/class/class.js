'use strict';

angular.module('myApp.class', ['ngRoute'])

.config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/class', {
    templateUrl: 'class/class.html',
    controller: 'ClassCtrl'
  });
}])
// Controller for Table of Contents
.controller('ClassCtrl', ['$location','$anchorScroll','$scope', '$sce', '$compile', '$window', '$document', '$rootScope', '$http', 'classFactory', function($scope, $sce, $compile, $window, $document, $rootScope, $http, classFactory, $location,$anchorScroll) {
  $scope.jumpToElement = function(classElement) {
        // set the location.hash to the id of
        // the element you wish to scroll to.
        $location.hash(classElement);
        // call $anchorScroll()
        $anchorScroll();
      };
}])

// Factory for classes
.factory('classFactory',['$http','$rootScope', function($http, $rootScope) {
  return {};
}]);
