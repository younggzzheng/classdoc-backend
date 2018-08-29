///
/// 	Hello! To use set up a REST App in the Management Portal 
///		Calls can then be made to the REST endpoints below.
Class ClassDocAPI.v1.REST Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
			  <Route Url="/TOC" Method="GET" Call="getBasePackages" />
			  <Route Url="/class/:className" Method="GET" Call="getClass" />
			  <Route Url="/package/:packageName" Method="GET" Call="getPackage" />
			  <Route Url="/subclass/:subclassName" Method="GET" Call="getSubclasses" />
			  <Route Url="/search/:query" Method="GET" Call="search" />
  			  <Route Url="/TOC/:namespace" Method="POST" Call="changeNamespace" />
			  
			  <Route Url="/test" Method="POST" Call="test" />
			  

		</Routes>
}
/// Returns the TOC
ClassMethod getBasePackages() As %Status
{
		write ##class(ClassDocAPI.v1.Utils).getTOC().%ToJSON()
		return $$$OK
}
/// Gets all the data from Querier.generateClass. Returns all info needed to render a class page.
ClassMethod getClass(className As %String)
{
	    #dim status As %Status = $$$OK
	    #dim e As %Exception.AbstractException
		try {
			//set className = $ZCONVERT(className,"I","URL")	// escaping URL back to UTF.
			write ##class(ClassDocAPI.v1.Querier).generateClass(className).%ToJSON()
		} catch(e) {
			set status = e.AsStatus()
			WRITE $System.Status.GetErrorText(status),!
		}
		return status
}
/// Gets all the data from Utils.getFamilyOfPackage. Returns all info needed to render a package page.
ClassMethod getPackage(packageName As %String)
{
	    #dim status As %Status = $$$OK
	    #dim e As %Exception.AbstractException
		try {
			//set packageName = $ZCONVERT(packageName,"I","URL")	// escaping URL back to UTF.
			write ##class(ClassDocAPI.v1.Utils).getFamilyOfPackage(packageName).%ToJSON()
		} catch(e) {
			set status = e.AsStatus()
			WRITE $System.Status.GetErrorText(status),!
		}
		return status
}
/// Gets all the data from Utils.getSubclasses. Gives a list of subclasses of a class.
ClassMethod getSubclasses(subclassName As %String)
{
	    #dim status As %Status = $$$OK
	    #dim e As %Exception.AbstractException
		try {
			//set subclassName = $ZCONVERT(subclassName,"I","URL")	// escaping URL back to UTF.
			write ##class(ClassDocAPI.v1.Utils).getSubclasses(subclassName).%ToJSON()
		} catch(e) {
			set status = e.AsStatus()
			WRITE $System.Status.GetErrorText(status),!
		}
		return status
}
/// Please read the Search.searchComponent documentation for description of how this method works. 
/// Returns the search results for query. flags are described in Search.
ClassMethod search(query As %String, desc As %Boolean = 0, showHidden As %Boolean = 0, caseSensitive As %Boolean = 0, top As %Integer = 500)
{
	    #dim status As %Status = $$$OK
	    #dim e As %Exception.AbstractException
		try {
			//set query = $ZCONVERT(query,"I","URL")	// escaping URL back to UTF.
			write ##class(ClassDocAPI.v1.Search).search(query, desc, showHidden, caseSensitive, top).%ToJSON()
		} catch(e) {
			set status = e.AsStatus()
			WRITE $System.Status.GetErrorText(status),!
		}
		return status
}

ClassMethod changeNamespace(namespace){
	write namespace
	
    #dim status As %Status = $$$OK
    #dim e As %Exception.AbstractException
	try {
		set ^ClassDocNamespace = namespace
	} catch(e) {
		set status = e.AsStatus()
		WRITE $System.Status.GetErrorText(status),!
	}
	return status
}


ClassMethod test()
{
	write ##class(ClassDocAPI.v1.Querier).generateClass("%DeepSee.AbstractKPI").%ToJSON()
}

}
