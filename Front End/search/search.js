'use strict';

angular.module('myApp.search', ['ngRoute'])

.config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/search', {
    templateUrl: 'search/search.html',
    controller: 'SearchCtrl'
  });
}])
// Controller for search
.controller('SearchCtrl', ['$scope', '$document', 'searchFactory', function($scope, $document, searchFactory) {
}])

// Retrieve JSON from REST API at url specified
.factory('searchFactory',['$http', function($http) {
  var searchFactory = {};
  return searchFactory;
}]);
