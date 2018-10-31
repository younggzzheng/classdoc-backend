 'use strict';


// Declare app level module which depends on views, and components
var app = angular.module('myApp', [
  'ngRoute',
  'myApp.search',
  'myApp.class',
  'myApp.package',
  'myApp.TOCView',
  'myApp.version',
  'ui.bootstrap'
]);

app.config(['$locationProvider', '$routeProvider', '$rootScopeProvider' ,function($locationProvider, $routeProvider, $rootScopeProvider) {
  $locationProvider.hashPrefix('!');

$routeProvider.otherwise({redirectTo: '/TOCView'});
  }])

// Factory for Table of Contents
.factory('TOCFactory',['$http','$rootScope', function($http, $rootScope) {
    var url = $rootScope.baseURL+'TOC';
    var TOCFactory = {};
    TOCFactory.getTOC = function () {
      return $http.get(url);
    };
    return TOCFactory;
}])

.directive('dynamic', function ($compile) {
  return {
    restrict: 'A',
    replace: true,
    link: function (scope, ele, attrs) {
      scope.$watch(attrs.dynamic, function(html) {
        ele.html(html);
        $compile(ele.contents())(scope);
      });
    }
  };
});

// Declaring variables global across all pages.
app.run(function($rootScope, $document, $sce, $http, $compile, $location, $window, $anchorScroll) {
  $rootScope.path = '';

  //$rootScope.baseURL = "http://iscdocs.iscinternal.com:52777/api/classdoc/";
  $rootScope.baseURL = "http://localhost:52773/api/documatic/";

  $rootScope.search = {
    phrase: ''
  }
  /******************************************************************************/
  // The function to jump to a specific element on a class page.
  $rootScope.jumpToElement = function(classElement) {
    var id = $location.hash();
    // set the location.hash to the id of
    // the element you wish to scroll to.
    $location.hash(classElement);
    // call $anchorScroll()
    $anchorScroll();
    $location.hash(id);
  };

  /******************************************************************************/
  // function to change namespace.
  $rootScope.changeNamespace = function() {
    var namespace = $scope.text;
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
  /******************************************************************************/
  $rootScope.getSearchResults = function() {
    $location.path('/search');
    $rootScope.classResults = "";
    $rootScope.methodResults = "";
    $rootScope.propResults = "";
    $rootScope.paramResults = "";
    var searchURL = $rootScope.baseURL + "search/" + encodeURI($rootScope.search.phrase);
    $http.get(searchURL)
    .then(
      function(response) {
        $rootScope.results = response.data;
        // Classes
        if ($rootScope.results.Classes.length) {
          var classes = '';
          $rootScope.results.Classes.forEach(function(elem) {
            classes += '<div class="item" ng-click="showClass(\'' + elem.ID + '\')"><b>' + elem.Name + '</b><br>' + elem.Description + '</div>';
          });
        } else {
          classes = "No classes found.";
        }
        $rootScope.classResults = $sce.trustAsHtml(classes);

        // Methods
        if ($rootScope.results.Methods.length) {
          var methods = '';
          $rootScope.results.Methods.forEach(function(elem) {
            methods += '<div class="item"><p class = "itemHeader">' + elem.Name + '</p><br><p>' + elem.Description + '</p></div>';
          });
        } else {
          methods = "No methods found.";
        }
        $rootScope.methodResults = $sce.trustAsHtml(methods);

        // Properties
        if ($rootScope.results.Properties.length) {
          var properties = '';
          $rootScope.results.Properties.forEach(function(elem) {
            properties += '<div class="item"><b>' + elem.Name + '</b></div>';
          });
        } else {
          properties = "No properties found.";
        }
        $rootScope.propResults = $sce.trustAsHtml(properties);

        // Parameters
        if ($rootScope.results.Parameters.length) {
          var params = '';
          $rootScope.results.Parameters.forEach(function(elem) {
            params += '<div class="item"><b>' + elem.Name + '</b></div>';
          });
        } else {
          params = "No parameters found.";
        }
        $rootScope.paramResults = $sce.trustAsHtml(params);
    });
  };
  /******************************************************************************/
  $rootScope.contentTitle = '';

  // given a member object data (like a local method), outputs the html paragraph of its keywords.
  $rootScope.getKeywords = function(memberObject){
    var data = memberObject;
    var keywordHTML = '';
    for (var key in data) {
      if (data.hasOwnProperty(key) && !(data[key] === Object(data[key]))) {
        if (!(key == 'Name' || key == 'Description' || key == 'ReturnType' || key =='Signature')) {
          if (data[key]==1) {data[key] = 'True';}
          keywordHTML += '<p>'+ key + ': '+ data[key]+'</p>';
        }
      }
    }
    var keywordTitle = ''
    if (keywordHTML != '') {keywordTitle = '<h4 class = "keywordTitle">Keywords</h4>';}
    return '<div class="classDescription" >'+ keywordTitle + keywordHTML +'</div>';
  }

  $rootScope.showClass = function (key) {
    $location.path('/class');
    var classURL =  $rootScope.baseURL + "class/" + encodeURIComponent(key);
    $http.get(classURL)
    .then(
      function(response) {
        $rootScope.className = response.data.Name;
        $rootScope.Description = response.data.Description;
        var data = response.data;
        $rootScope.path = '';
        var classInfo = '';
        var methodTable = '';
        var methodBoxes = '';
        var propertiesTable = '';
        var propertyBoxes = '';
        var parameters = '';
        var abstract = '';
        var superClasses = '';
        var keywordTable= '';
        if (data.Abstract == 1) {abstract = 'abstract'};
        if (data.hasOwnProperty('SuperClasses')) {
          superClasses = ' extends '
          data.SuperClasses.forEach(function(superclass) {
            superClasses += ' ' + superclass
          })
        }
        var keywords = $rootScope.getKeywords(response.data);
        classInfo +='<p class = "signature">'+ abstract + ' class ' + data.Name + superClasses +'</p>';
        classInfo +='<p class = "classDescription">'+$rootScope.Description+'</p>';
        classInfo +=keywords;

          if (response.data.Methods.LocalMethods.length) {
          methodTable = '<h3>Methods Overview</h3><table><tr><th>Name</th><th>Returns</th></tr>';
          methodBoxes = '<h3>Methods</h3>';
          var returnType = "";
          response.data.Methods.LocalMethods.forEach(function(elem) {
            if (!elem.hasOwnProperty('Description')) {elem.Description = ""}
            if (elem.hasOwnProperty('ReturnType')) {
              if (typeof elem.ReturnType == 'undefined') {
                 returnType = " As %Library.Status" ;
              } else {
              returnType = " As " + elem.ReturnType;
            }
            }
            var tableReturnType = "";
            if (typeof elem.ReturnType == 'undefined') {
               tableReturnType = "%Library.Status" ;
            } else {
              tableReturnType = elem.ReturnType;
            }

            methodTable += '<tr><td><a ng-click = "jumpToElement(\''+elem.Name+'\')">' + elem.Name +  '</a></td><td>' + tableReturnType + '</td></tr>';
            methodBoxes += '<div id = "'+elem.Name+'" class="method item"> <h4 class = "itemHeader">' + elem.Name + '</h4> <hr class="horizontalLine">';
            methodBoxes +=  '<p class = "signature">' + elem.Name + elem.Signature + returnType + '</p>';
            if (!elem.hasOwnProperty('Description')) {elem.Description = ""}
            methodBoxes += '<br><p>' + elem.Description + $rootScope.getKeywords(elem) +'</p> </div><br>';

          })
        }

        if (response.data.Properties.LocalProperties.length) {
          propertiesTable = '<h3>Properties Overview</h3><table><tr><th>Name</th><th>Description</th></tr>';
          response.data.Properties.LocalProperties.forEach(function(elem) {
            propertiesTable += '<tr><td>' + elem.Name + '</td><td>' + elem.Description + '</td></tr>';
            propertyBoxes += '<div id = "'+elem.Name+'" class="method item"> <h4 class = "itemHeader">' + elem.Name + '</h4> <hr class="horizontalLine">';
            propertyBoxes += '<br><p>' + elem.Description + $rootScope.getKeywords(elem) +'</p> </div>';
          })
        }

        if (response.data.Parameters.length) {
          parameters = '<h3>Parameters</h3>';
          response.data.Parameters.forEach(function(elem) {
            if (!elem.hasOwnProperty('Description')) {elem.Description = ""}
            parameters += '<div class="method item"><h4>' + elem.Name + '</h4><br><p>' + elem.Description +'</p>' + $rootScope.getKeywords(elem) + '</div><br>';
          })
        }
        if (propertyBoxes.length) {
          propertyBoxes = '<h3> Properties </h3>'+ propertyBoxes ;
        }
        $rootScope.propertiesTable = $sce.trustAsHtml(propertiesTable + '</table> <hr>');
        $rootScope.propertyBoxes = $sce.trustAsHtml(propertyBoxes + '<hr>');
        $rootScope.methodTable = $sce.trustAsHtml(methodTable + '</table><hr>');
        $rootScope.parameters = $sce.trustAsHtml(parameters + '</div><hr>');
        $rootScope.methodBoxes = $sce.trustAsHtml(methodBoxes + '</div><hr>');
        $rootScope.classInfo =  $sce.trustAsHtml(classInfo);

    /**************************** SIDE NAV GENERATING **********************/
    var path = '';
    var family = response.data.Family;
    var cIcon = '<span style = "display:inline-block;"><img src="https://www.scala-lang.org/api/current/lib/class.svg" style="width:15px"></img></span>';
    var pIcon = '<span style = "display:inline-block;"><img src="https://www.scala-lang.org/api/2.12.6/scala-reflect/lib/package.svg" style="width:15px"></img></span>';
    var ancestors = 0;
    family.AncestorPackages.forEach(function(pack) {
    var tabs = '<span style = "display:inline-block;">';
      for (var i = 0; i<ancestors; i++){
        tabs += '&emsp;&emsp;';
      }
      tabs += '</span>';
      ancestors = ancestors + 1;
      path += '<a ng-click="showPackage(\'' + pack + '\')">' + tabs + pack + '</a>';
    });
    path += '<div class="sibling-cl">';
    family.SiblingClasses.forEach(function(cl) {
      path += '<a ng-click="showClass(\'' + cl + '\')">' +cIcon + '&ensp;' + cl + '</a>';
    });
    path += '</div><div class="sibling-pack">';
    family.SiblingPackages.forEach(function(pack) {
      path += '<a ng-click="showPackage(\'' + pack + '\')">'  + pIcon + '&ensp;' + pack + '</a>';
    });
    path += '</div>';
    $rootScope.path = $sce.trustAsHtml(path);
  });
};
  /******************************************************************************/
  $rootScope.showPackage = function (key) {
    $location.path('/package');
    var packageURL =  $rootScope.baseURL + "package/" + encodeURIComponent(key);
    $http.get(packageURL)
    .then(
      function(response) {
        $rootScope.packageName = key;
        $rootScope.path = '';
        var Subpackages = '';
        var Subclasses = '';
        Subpackages = '<h3>Subpackages</h3>';
        if (response.data.Subpackages.length) {
          response.data.Subpackages.forEach(function(elem) {
            Subpackages += '<a ng-click="showPackage(\'' + elem + '\')">' + elem + '</a><br>';
          })
        }
        Subclasses = '<h3>Subclasses</h3>';
        if (response.data.Subclasses.length) {
          response.data.Subclasses.forEach(function(elem) {
            Subclasses += '<a ng-click="showClass(\'' + elem + '\')">' + elem + '</a><br>';
          })
        }
        $rootScope.Subpackages = $sce.trustAsHtml(Subpackages);
        $rootScope.Subclasses = $sce.trustAsHtml(Subclasses);

        /**************************** SIDE NAV GENERATING **********************/
        // it's repeated code, I know :( this was just the quickest way to do it.
        /**************************** SIDE NAV GENERATING **********************/
        var path = '';
        var family = response.data;
        var cIcon = '<span style = "display:inline-block;"><img src="https://www.scala-lang.org/api/current/lib/class.svg" style="width:15px"></img></span>';
        var pIcon = '<span style = "display:inline-block;"><img src="https://www.scala-lang.org/api/2.12.6/scala-reflect/lib/package.svg" style="width:15px"></img></span>';
        var ancestors = 0;
        family.AncestorPackages.forEach(function(pack) {
          var tabs = '<span style = "display:inline-block;">';
          for (var i = 0; i<ancestors; i++){
            tabs += '&emsp;&emsp;';
          }
          tabs += '</span>';
          ancestors = ancestors + 1;
          path += '<a ng-click="showPackage(\'' + pack + '\')">' + tabs + pack + '</a>';
        });
        path += '<div class="sibling-cl">';
        family.SiblingClasses.forEach(function(cl) {
          path += '<a ng-click="showClass(\'' + cl + '\')">' +cIcon + '&ensp;' + cl + '</a>';
        });
        path += '</div><div class="sibling-pack">';

        family.SiblingPackages.forEach(function(pack) {
          path += '<a ng-click="showPackage(\'' + pack + '\')">'  + pIcon + '&ensp;' + pack + '</a>';
        });


        path += '</div>';
        $rootScope.path = $sce.trustAsHtml(path);
      });
    };
  });
