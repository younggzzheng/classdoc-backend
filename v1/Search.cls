/// Contains all methods for searching through Class Reference. searchComponent documentation has most of the 
/// important information. Method "search" is a wrapper method for searchComponent.

Class ClassDocAPI.v1.Search
{

///	Given a class name, a DynamicArray of all classes whose names contain the substring inputted.
///	This is case insensitive, results in alphabetical order.
///	Searches in ClassDefinition/WhateverDefinition
///	desc adds an OR clause to the SQL statement, searching for case insensitive match in Description.
/// showHidden when set to 1 will show hidden classes.
/// caseSensitive will search caseSensitive.
///	top, default to 300. Sets the number of results taken back. set to -1 for all results.
ClassMethod searchComponent(query As %String, type As %String, desc As %Boolean = 0, showHidden As %Boolean = 0, caseSensitive As %Boolean = 0, top As %Integer = 300) As %DynamicArray
{
	  do ^%ZDocBookBoost
	  new $namespace
	  if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
	  set $namespace = ^ClassDocNamespace
	  set query = $$$UPPER(query)
	  if (top '= -1) {set top = "TOP "_top}
	  SET myquery = "SELECT "_top_" Name, Description, ID FROM %Dictionary."_type_"Definition WHERE %UPPER(Name) [ '" _ query _ "'"
	  
	  if (type = "Class") {set myquery = myquery _ "AND Hidden = 0"} // you can add additional filters like this
	  if (desc = 1) {set myquery = myquery _ "OR %UPPER(Description) [ '" _ query _ "'"}
	 
	  SET tStatement = ##class(%SQL.Statement).%New()
	  SET qStatus = tStatement.%Prepare(myquery)
	  SET rset = tStatement.%Execute()
	  SET toReturn = [] // creates a dynamic array
	  set counter = 0
	  WHILE rset.%Next() { //TODO: this is just a 
	  	set classObj = {}
	  	set classObj.Name = rset.Name
	  	set classObj.Description = rset.Description
	  	set classObj.ID = rset.ID
 	  	do toReturn.%Push(classObj)
 	  	set counter = counter + 1 //TODO: return the counter somehow
 	  	//if (counter > 4000) {write !, "<DEBUG>:"_ type _" more than 4000 results." return toReturn}
	  }
  	  //write !, "Found "_counter_ " "_ type_" results for query: " _ query
	  return toReturn
}

///	Given a method name, returns a DynamicArray of all methods whose names(not IDs) contain the substring inputted.
///	This is case insensitive, results in alphabetical order.

ClassMethod searchMethods(query As %String, desc As %Boolean = 0, showHidden As %Boolean = 0, caseSensitive As %Boolean = 0, top As %Integer = 300) As %DynamicArray
{
	do ^%ZDocBookBoost
	new $namespace
	if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
	set $namespace = ^ClassDocNamespace
	set query = $$$UPPER(query)  
	  
	  if (top '= -1) {set top = "TOP "_top}
	  SET myquery = "SELECT "_top_" Name, Description, ID, parent FROM %Dictionary.MethodDefinition WHERE %UPPER(Name) [ '" _ query _ "'"
	  SET tStatement = ##class(%SQL.Statement).%New()
	  SET qStatus = tStatement.%Prepare(myquery)
	  SET rset = tStatement.%Execute()
	  SET toReturn = [] // creates a dynamic array
	  set counter = 0
	  WHILE rset.%Next() {
  	  	set compiledObj =  ##class(%Dictionary.CompiledMethod).%OpenId(rset.ID,0)
	  	if (compiledObj '= "") {
	  	  	set classObj = {}
		  	//set truncatedDescription = $EXTRACT(rset.Description,1,200) _ "..."
		  	set signature = ##class(ClassDocAPI.v1.Utils).SpecToSignature(compiledObj.FormalSpecParsed)
		  	set classObj.Name = rset.Name
		  	set classObj.ID = rset.ID
		  	set classObj.Description = rset.Description
		  	set classObj.FormalSpecParsed = rset.Name_signature
		  	set classObj.Parent = rset.parent
	 	  	do toReturn.%Push(classObj)
	 	  	set counter = counter + 1
	 	  	//if (counter > 4000) {write !, "<DEBUG>:"_ "Methods" _" more than 4000 results." return toReturn}
	 	  	
 	  	} else {
 	  		//write !, rset.ID
 	  	}
	  }
	  //write !, "Found "_counter_ " Method results for query: " _ query
	  return toReturn
}
/// Used for testing speed
ClassMethod speedTest(query)
{
		 set beginning = $p($h,",",2)
		 do ..search(query)
		 set end = $p($h,",",2)
		 write !, "Search took: " _ (end - beginning) _ " seconds."
}
/// wrapper method for search component.
ClassMethod search(query As %String, desc As %Boolean = 0, showHidden As %Boolean = 0, caseSensitive As %Boolean = 0, top As %Integer = 300)
{
		 set Classes = ..searchComponent(query, "Class",desc,showHidden,caseSensitive,top)
		 set Methods = ..searchMethods(query,desc,showHidden,caseSensitive,top)
		 set Properties = ..searchComponent(query, "Property",desc,showHidden,caseSensitive,top)
		 set Parameters = ..searchComponent(query, "Parameter",desc,showHidden,caseSensitive,top)
		 set Queries = ..searchComponent(query, "Query",desc,showHidden,caseSensitive,top)
		 set toReturn = {}
		 set toReturn.Classes = Classes
		 set toReturn.Methods = Methods
		 set toReturn.Properties = Properties
		 set toReturn.Parameters = Parameters
		 set toReturn.Queries = Queries
		 return toReturn
}

}

