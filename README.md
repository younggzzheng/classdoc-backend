# ClassDoc
Front-end and back-end for automated class reference developed for InterSystems Corporation

ClassDoc is a new Class Reference Documentation Web App
  - Written by 2018 Summer Intern Young Zheng for the Documentation Team
  - Email Young Zheng at zhaoyong_zheng@brown.edu
  - App is still under construction so excuse the appearance!

## Executing
The API is currently running on http://iscdocs.iscinternal.com:52777/api/classdoc/, but it needs to be reloaded with the new code each time it's updated.

To run the front end app, navigate to https://nodejs.org/en/download/ to download Node.js, then follow the steps in https://docs.npmjs.com/getting-started/installing-node to install npm.

Once npm is installed and ready to go, cd to the directory you want to run, which should be .../classdoc-ui.
Once inside this directory, run by typing npm start. The correct packages and frameworks will then be installed, and the app will be running on localhost:8000. Note that if there's another thing taking the 8000 port, the build will fail.

### The API
The backend is written in ObjectScript and uses %SQL.Statement to execute queries to pull class data from the %Dictionary class. This class data is processed in Querier into a %DynamicObject. Important to note is that Querier uses the automatically generated IsDefined() methods for each component of the class, so a class that does not have Abstract defined will not have an Abstract attribute. The complete object can be obtained by making a call to generateClass(classname). This DynamicObject is turned into a JSON string in REST.cls, where a call to generateClass is used as input to %ToJSON(). This string output is the output of the REST API.

Namespace is changed by changing the global ^ClassDocNamespace to "USER", or whatever your namespace is. ClassMethod changeNamespace(namespace) is in the REST class, and should be changed through a POST request to /TOC/:namespace.


### The JSON String
The object is structured as follows: A class has attributes of its own, such as name, description, abstract, etc., and it also has class components, listed as Methods, Parameters, Properties, Queries, Indicies, Foreign Keys, and Triggers.
It also has a family, which describes sibling packages and classes, and ancestor packages.

Each of the class components has it's own components, with Methods and Properties having subsections of Local/Inherited Methods and Local/Inherited Properties respectively. These special subobjects exist because Methods and Properties can be inherited from superclasses, and the API needs a way to differentiate between methods defined in the actual class itself and those inherited from its super classes.

Additional keywords can be added in generateClass. However, you must make sure that the IsDefined method exists for any additional keywords added. If they do not, you can add them in getComponents.  

### The Front End
Currently the front end is written in AngularJS, but plans are to upgrade it to Angular Material. The ClassDoc front end does very little work as far as processing incoming data. The goal was to make it so that all the data coming out of the API would be human readable once a bit of formatting was done.

The Angular App is built off of the Angular seed app and uses Bootstrap (minimally), and nothing else. Once upgraded to the new version, routing can be added as well as additional UI improvements.

Currently the app is split into four sections:
#### 1) Class
    Contains all the information necessary for a class. Additional class components can be added very easily in app.js.
#### 2) Table of Contents:
    Simply renders all the top level packages with clickable links to take you to those package pages.
#### 3) Package
    In two columns, renders the Subpackages and Subclasses as links. There is the same sidebar as in Class.
#### 4) Search
    Can eventually be changed so that there are drop down menus for advanced search such as case sensitive and search in description. For now a skeleton for these features is in place.

The search bar on the top of the page is persistent across all pages and has a fixed location on the page.

### Angular App File structure
There are folders for each of the four views, with the HTML and JS file being contained within the corresponding folders. app.js contains all the functions that are to be run either at runtime (contained in app.run) or $rootScope functions that are to be used across all views.

#### Major Methods
showClass, showPackage, and getSearchResults are contained inside of app.run in the app.js file. These are the main functions that dynamically generate HTML according to the API output and bind HTML to "dynamic" directives. If you want to alter the information that is displayed on a class page, you would do so in app.run instead of class.js (unintuitive, I know, but in Angular 6 this will be made easier.)

There are a few helper utility methods spread throughout, but an important one is getKeywords. It runs through all the attributes of a JSON object and renders them out in a paragraph. This list will match the list in keywordsCSV from the API. If you want to not render certain attributes, you can add to the conditional with the key!="string" within the method.

#### Index
index.html contains all the scripts to import Angular app boilerplate. It is also where you would put persistent page components, such as the search bar. Any new JS files must be included at the bottom where all the other JS files are, within <script> tags. This is also where you would add additional frameworks like JQuery.
