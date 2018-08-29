/// Utilites for ClassDocAPI:
/// * SpecToSignature and SpecToArray: Create a signature based off of the FormalSpecParsed
/// * getSubpackages
/// * getSubclasses
/// * getTOC: all of the top level packages for the table of contents.
/// * getFamilyOfClass: gives the sibling and ancestor packages/classes.
Class ClassDocAPI.v1.Utils
{

/// input list must follow the form of the %Dictionary.CompiledMethod's FormalSpecParsed. This method turns that query into a dynamic array.
/// & for byref, * for outputonly. 
ClassMethod SpecToArray(outerlist) As %DynamicArray
{
	    set toReturn = []
	    for i=1:1:$LISTLENGTH(outerlist) {
	    	set innerlist=$LIST(outerlist,i)
	    	set argObj = {}
	    	if ($LISTLENGTH(innerlist) < 4) { 
				SET mygenex = ##class(%Exception.General).%New("SpecToArray Exception",,,"The spec list: '"_outerlist_"' cannot have fewer than 4 components (name, type, byref, output)[parametername, parametervalue]")
	    		throw mygenex
	    	}
	    	// $lb("pClassName","%Library.String","&","","MAXLEN","1","MAXVAL","15")
	    	//for j=1:1:$LISTLENGTH(innerlist) {}
	    		set argObj.argName = $LIST(innerlist,1)
	    		set argObj.retType = $LIST(innerlist,2)
	    		set argObj.ByRef = $LIST(innerlist,3)="&"
	    		set argObj.OutputOnly = $LIST(innerlist,4)="*"
	    		
	    		for j=5:1:$LISTLENGTH(innerlist) {
	    				
	    		}
	    	do toReturn.%Push(argObj)
	    }
		return toReturn
}

/// Generates a signature for a method.
///	Sample Output: (ByRef arg1 As %String(MAXLEN=5000, XMLKEYNAME="Name", XMLPROJECTION="elementt")=3, Arg2 As %String = 2)
///				   (ByRef arg1 As %String(MAXLEN = 5000, XMLKEYNAME = "Name", XMLPROJECTION = "elementt"), Arg2 As %Library.String)
				   
ClassMethod SpecToSignature(formalSpecParsed) As %String
{
	//$lb("arg1","%Library.String","","3","MAXLEN","5000","XMLKEYNAME","""Name""","XMLPROJECTION","""elementt""")
	//arg1 As %String(MAXLEN = 5000, XMLKEYNAME = "Name", XMLPROJECTION = "elementt") = 3
		set toReturn = "("
		for i = 1:1:$LISTLENGTH(formalSpecParsed) {
			set argComps = $LIST(formalSpecParsed,i)
			set name = $LIST(argComps, 1)
			set type = $LIST(argComps, 2) //TODO: make a link for the type
			set byRef = $LIST(argComps, 3)
			
			if (byRef = "&") {set byRef = "ByRef "} else {
			if (byRef = "*") {set byRef = "Output "} else {set byRef = ""}}
			set default = ""
			if ($LIST(argComps, 4) '= "") {set default = " = " _ $LIST(argComps,4)}
			set toReturn = toReturn _ byRef _ name_" As "_type
			// fill in Parameters
			set parameters = ""
			set j = 5	// 5 because the first 4 list elements are always the same 4 things.
			if ($LISTLENGTH(argComps) > 4) {
			set parameters = "("
			
			while (j < ($LISTLENGTH(argComps)-1)) {//9
				set parameters = parameters _ $LIST(argComps, j) _ " = " _ $LIST(argComps,j+1)_", "
				set j = j + 2
			}
			// final 2 elements are treated differently (without the comma)
			set parameters = parameters _ $LIST(argComps, j) _ " = " _ $LIST(argComps,j+1)_")"
			}
			set toReturn = toReturn _ parameters _ default
			if ((i+1)<=$LISTLENGTH(formalSpecParsed)) {set toReturn = toReturn _ ", "} // dont want to add comma on last iteration.
		}
		set toReturn = toReturn _ ")"
		return toReturn
}


/// Given a package, Returns a dynamic array with each array element containing the %String name of its subpackages.
/// Use * as package name to get all packages.
ClassMethod getSubpackages(package As %String) As %DynamicArray
{
		new $namespace
		if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
		set $namespace = ^ClassDocNamespace
		do ^%ZDocBookBoost
		set regEx = package _ ".*.*"
		set tokenizedInputPackage = $LISTFROMSTRING(package, ".") // break up input name into period delimited string list.
        set inputPackagePathLength = $LISTLENGTH(tokenizedInputPackage) // get the length of that list.
        set uniqueList = $LISTBUILD() 	// keeps track of all of the uniquepackages. This list gets populated alongside toReturn because we can perform LISTFIND on it.
		// <-- TODO: make sure this is okay to do: classDefinitinon instead of compiledclass -->
		&sql(declare Subpackages cursor for 
		SELECT
		ID
		FROM %Dictionary.ClassDefinition 
		WHERE ID %MATCHES :regEx
			)
	    &sql(open Subpackages)
	    set toReturn = [] // creates a dynamic array
	    while (SQLCODE = 0) { // keep going as long as there are still elements AND no issues have occured
	        &sql(fetch Subpackages into :queriedSubpackagePath)
	        quit:(SQLCODE)
	        set tokenizedQueriedSubpackagePath = $LISTFROMSTRING(queriedSubpackagePath, ".")
	        set queriedPathLength = $LISTLENGTH(tokenizedQueriedSubpackagePath)
	        set packageNameToPush = $LIST(tokenizedQueriedSubpackagePath, 1, inputPackagePathLength + 1)
	        set packageAsString = $LISTTOSTRING(packageNameToPush, ".")
	        if ((queriedPathLength > 1 + inputPackagePathLength) && '$LISTFIND(uniqueList,packageAsString)) {  /*path we just found is at least 1 subpackage deeper than input && is unique in list*/ 
	        	// also add to unique list so next time you wont add it to the dynamicArray again.
	        	SET $LIST(uniqueList,*+1) = packageAsString
	        	do toReturn.%Push(packageAsString) // add to DynamicArray that we're going to return.
	        }
	    }
	   // w toReturn.%ToJSON()
	    &sql(close Subpackages)
	    quit toReturn
}
/// Returns the top level packages of the namespace.
ClassMethod getTOC() As %DynamicArray
{
	new $namespace
	if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
	set $namespace = ^ClassDocNamespace
	do ^%ZDocBookBoost
    set uniqueList = $LISTBUILD() 	// keeps track of all of the uniquepackages. This list gets populated alongside toReturn because we can perform LISTFIND on it.
	set toReturn = []
	&sql(declare Subpackages2 cursor for 
	SELECT ID 
	FROM %Dictionary.ClassDefinition )
    &sql(open Subpackages2)
    while (SQLCODE = 0) { // keep going as long as there are still elements AND no issues have occured
    &sql(fetch Subpackages2 into :queriedSubpackagePath)
    quit:(SQLCODE)
    set tokenizedQueriedSubpackagePath = $LISTFROMSTRING(queriedSubpackagePath, ".")
    set packageNameToPush = $LIST(tokenizedQueriedSubpackagePath, 1)
    if ('$LISTFIND(uniqueList,packageNameToPush)) {  /*path we just found unique in list*/ 
    	// also add to unique list so next time you wont add it to the dynamicArray again.
    	SET $LIST(uniqueList,*+1) = packageNameToPush
    	do toReturn.%Push(packageNameToPush) // add to DynamicArray that we're going to return.
    	}
    }
    &sql(close Subpackages2)
    return toReturn
}


///	Gets all the subclasses of a package and returns it as a dynamic array.
///		1) Find out the length of the package path + 1.
///		2) Iterate through all classes whos ID's follow the form package.*
///		3) Add to DynamicArray all the classes that are length+1 long only.
ClassMethod getSubclasses(package As %String) As %DynamicArray
{
		new $namespace
		if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
		set $namespace = ^ClassDocNamespace
		do ^%ZDocBookBoost
		set regEx = package _ ".*"
		set tokenizedInputPackage = $LISTFROMSTRING(package, ".") // break up input name into period delimited string list.
        set inputPackagePathLength = $LISTLENGTH(tokenizedInputPackage) // get the length of that list.
        set toReturn = []
		&sql(declare Subclasses cursor for 
		SELECT ID
		FROM %Dictionary.ClassDefinition
		WHERE ID %MATCHES :regEx
		AND hidden = '0')
        &sql(open Subclasses)    
        while (SQLCODE = 0) { // keep going as long as there are still elements AND no issues have occured
        &sql(fetch Subclasses into :queriedSubclassPath)
	        quit:(SQLCODE)
	        set parsedQuery = $LISTFROMSTRING(queriedSubclassPath, ".")
	        set queriedSubclassLength = $LISTLENGTH(parsedQuery) // get number of layers in queried
	        if (queriedSubclassLength = (inputPackagePathLength + 1)) { // if it's same as 1+input length, add it. 
	        	do toReturn.%Push(queriedSubclassPath)
	        }
	    }
	    &sql(close Subclasses)
        return toReturn
}
/// 	Wrapper method for getSubclasses and getSubpackages.
///		Contains SiblingClass, SiblingPackages, AncestorPackages

	ClassMethod getFamilyOfClass(class As %String) As %DynamicObject{
		set toReturn = {}
		set toReturn.SiblingClasses =  ..getSubclasses(..getParent(class))
		set toReturn.SiblingPackages =  ..getSubpackages(..getParent(class))
		set toReturn.AncestorPackages = ..getAncestors(class)
		return toReturn
	}
	

///		FOR PACKAGES ONLY:
///		This method is for rendering a sidenav that allows you to navigate up and down the class tree.
///		Input: Package like A or A.B
///		Output: Dynamic object with 5 components: SiblingClasses, SiblingPackages,  AncestorPackages, Subpackages, Subclasses
///			Siblings are all the packages on the same level in the tree, AncestorPackages trace from root to node
///			all the packages it took to get to that package or class.

	ClassMethod getFamilyOfPackage(package As %String) As %DynamicObject{
		set toReturn = {}
		set toReturn.SiblingClasses = []
		set toReturn.SiblingPackages = []
		set toReturn.AncestorPackages = []
		set toReturn.Subpackages = []
		set toReturn.Subclasses = []
		set list = $LISTFROMSTRING(package,".")
		set length = $LISTLENGTH(list)
		/* Empty string is invalid input.*/
		if (length = 0) {return {}}
		set toReturn.Subpackages = ..getSubpackages(package)
		set toReturn.Subclasses = ..getSubclasses(package)
		
		/*  Length 1 means it must be a top level package. 
			If a package has no enclosing package, it cannot have sibling classes.
			SiblingPackage of top level is the Table of Contents
			No ancestor pacakges.
		*/
		if (length = 1) {
			set toReturn.SiblingClasses = []
			set toReturn.SiblingPackages = ..getTOC()
			set toReturn.AncestorPackages = []
		} else {
			set toReturn.SiblingClasses =  ..getSubclasses(..getParent(package))
			set toReturn.SiblingPackages =  ..getSubpackages(..getParent(package))
			set toReturn.AncestorPackages = ..getAncestors(package)
		}
		return toReturn
	}
	
/// must be at least A.B depth. 
///	   Input->Output: A.B -> A ; A.B.C -> A.B
	ClassMethod getParent(ID As %String) As %String {
		set list = $LISTFROMSTRING(ID,".")
		set length = $LISTLENGTH(list)
		return $LISTTOSTRING($LIST(list,1,(length-1)),".")
	} 
	

///		Input: A.B.C.D
///		Output: [A, A.B, A.B.C]
	
	ClassMethod getAncestors(ID As %String) As %DynamicArray {
		set list = $LISTFROMSTRING(ID, ".")
		set toReturn = []
	    for i=0:1:($LISTLENGTH(list)-2) {
	    	do toReturn.%Set(i, $LISTTOSTRING($LIST(list,1,i+1),"."))
	    }
	    return toReturn
	}


}

