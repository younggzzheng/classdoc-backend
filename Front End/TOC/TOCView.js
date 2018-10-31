'use strict';

angular.module('myApp.TOCView', ['ngRoute'])

.config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/TOCView', {
    templateUrl: 'TOC/TOCView.html',
    controller: 'TOCCtrl'
  });
}])
// Controller for Table of Contents
.controller('TOCCtrl', ['$scope', '$document', 'TOCFactory', function($scope, $document, TOCFactory) {
  $scope.TOCPackages
  getTOC();
  function getTOC() {
    TOCFactory.getTOC()
        .then(function (response) {
            $scope.TOCPackages = response.data;
          }, function (error) {
            $scope.status = 'Unable to load documentation:' + error.message;
          });
  }

  // function to change namespace.
  $scope.changeNamespace = function(namespace) {
    var url = $rootScope.baseURL + "TOC/" + namespace;
    var data = 'parameters';
    var config = {
                    headers : {
                        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8;'
                    }
                }
    $http.post(url, data, config).then(function (response) {
    // This function handles success
    }, function (response) {
    // this function handles error
    });
  };
}]);
