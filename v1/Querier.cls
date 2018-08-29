/// The Querier Class contains most of the core functionality of the ClassDocAPI. It queries the %Dictionary class to get all
/// of the necessary information to generate a class object. The purpose of this class is to generate one single %DynamicObject 
/// object to be turned into a JSON string in the REST class.
/// 
/// generateClass is the method that builds the dynamic object. All other methods are helper methods and not outward facing. 


Class ClassDocAPI.v1.Querier
{
///		classPath: String. This is the ID of the class/method/attribute in <tableName> that you're trying to get the components of. 
///			   Ex: %Api.Atelier
///
///		componentName: This is an argument that is the type of component you're getting, so "Method", "Class", "Parameter" are valid inputs.
///		They have to match names in %Dictionary. Note that if you do not input the exact correct string, method will break.
///		
///		keywordsCSV: String. All the keywords that you want your object to describe. The CSV for CompiledMethod is:
///		"Abstract,ClientName,CodeMode,Deprecated,ExternalProcName,Final,ForceGenerate,GenerateAfter,Internal,Language,NotInheritable,PlaceAfter,Private,ProcedureBlock,PublicList,ReturnResultsets,ServerOnly,SoapAction,SoapBindingStyle,SoapBodyUse,SoapMessageName,SoapNameSpace,SoapRequestMessageSoapTypeNameSpace,SqlName,SqlProc,WebMethod" 
///	
///		Returns a DynamicObject with all the keywords filled in. Important to note that it will return {} if the class doesn't exist in both Compiled and Definition, so
///		you must catch that in whatever calls it. Also, it'll return {} if classes are hidden.
///		
///		If you input with componentName = "Methods", it will call SpecToSignature in Utils to add another attribute, "Signature", to the returned object.

ClassMethod getComponents(classPath As %String, componentName As %String, keywordsCSV As %String) As %DynamicObject
{
		
		do ^%ZDocBookBoost
		new $namespace
		if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
		set $namespace = ^ClassDocNamespace
		set classObject = {}
		set keywordList = $LISTFROMSTRING(keywordsCSV, ",")
		set toReturn = {} // JSON object to return
		
		set compiledName = "%Dictionary.Compiled" _ componentName // %Dictionary.CompiledMethod
		set definitionName = "%Dictionary." _ componentName _ "Definition"
		
		set classObjCompiled =  $CLASSMETHOD(compiledName, "%OpenId", classPath, 0) 	// set classObj =  ##class(%Dictionary.CompiledMethod).%OpenId(classPath,0)
		set classObjDefinition =  $CLASSMETHOD(definitionName, "%OpenId", classPath, 0) 	// set classObj =  ##class(%Dictionary.MethodDefinition).%OpenId(classPath,0)
		if ((classObjCompiled = "") || (classObjDefinition = "")) { 
			SET mygenex = ##class(%Exception.General).%New("getComponents Exception",,,"could not get component of type: '"_componentName_"' with name: '"_ classPath_"'")
			//throw mygenex
			return {}
		}
		
		if (componentName = "Class" && classObjCompiled.Hidden = 1) { return {} } // hidden classes should not be shown.
		//if ((componentName = "Property") || (componentName =  "Parameter") || (componentName = "Query")) {set toReturn.Type = classObjCompiled.Type}
		set toReturn.Name = classObjCompiled.Name
		set ptr = 0, keyword = ""

		while($LISTNEXT(keywordList, ptr, keyword)) {
			set methodName = keyword_"IsDefined"
			set keywordDefined = $METHOD(classObjDefinition, methodName)	// set keywordDefined = classObject.AbstractIsDefined
			//write !, "DEBUG>: Is """_ keyword _ """ defined? : " _keywordDefined
			if (keywordDefined) {
			 	set prop = $PROPERTY(classObjCompiled, keyword)	
				do toReturn.%Set(keyword, prop)
			}
		}
		// --- additional specific keywords not in ROBJ ---
		if (componentName = "Method") {
			//set toReturn.FormalSpecParsed = ##class(API.Utilities).SpecToArray(classObjCompiled.FormalSpecParsed)
			set toReturn.Signature = ##class(ClassDocAPI.v1.Utils).SpecToSignature(classObjCompiled.FormalSpecParsed)
		}
		if ((componentName = "Class") && (classObjDefinition.SuperIsDefined())){
			set toReturn.SuperClasses = []
			set ptr = 0, super = ""		
			set superList = $LISTFROMSTRING(classObjCompiled.Super,",")
			while($LISTNEXT(superList, ptr, super)) {
				do toReturn.SuperClasses.%Push(super)
			}		
			
		}
		return toReturn
}


/// getComponentList gets the ID of every component(such as Method) in the input class, calls getComponent on them, and stores the resultant
/// objects in a DynamicArray. This DynamicArray is what getComponentList returns. 
///
/// Arguments
/// classPath: the name of the class you want to get components of.
/// componentName: the type of component--Parameter, for example.
/// keywordsCSV: same as the getComponent keywordsCSV.
/// local: this is written as Output because it returns a reference to a %List containing all localComponents of this class.
/// This output is used in method getInheritedComponents. Please refer to documentation for that method.


// local is passed in by reference. If the component is either Method or Parameter, local will contain a list of ID's of all local params/methods.
ClassMethod getComponentList(classPath As %String, componentName As %String, keywordsCSV As %String, Output local As %List) As %DynamicArray
{
	  new $namespace
	  if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
	  set $namespace = ^ClassDocNamespace
	  do ^%ZDocBookBoost
	  SET myquery = "SELECT ID, Name FROM %Dictionary."_componentName_"Definition WHERE parent = '" _ classPath _ "'"
	  SET tStatement = ##class(%SQL.Statement).%New()
	  SET qStatus = tStatement.%Prepare(myquery)
	  SET rset = tStatement.%Execute()
	  SET toReturn = [] // creates a dynamic array
	  set inherit = 0
	  if ((componentName = "Method") || (componentName = "Property")) { set inherit = 1 }  // inherit tag is true when component is method or parameter.
	  WHILE rset.%Next() {
 	  	SET componentObject = ..getComponents(rset.ID, componentName, keywordsCSV)
 	  	if (componentObject '= {}) {
 	  		DO toReturn.%Push(componentObject)	// only push the component object to the array if getComponents actually returns something. It will return {} if invalid component.
 	  	}
    	if (inherit) {SET $LIST(local,*+1) = rset.Name}  // populate the local list with IDs of local components.
	  }
	    return toReturn
}


/// Returns a DynamicArray with each item of the array being a inherited component of the input class name.
/// So if you input classPath = "%Api.Atelier", componentName = "Method", then it will return all inherited methods for Api.Atelier.
/// Important to note that this class depends on class findSuperclass's findSuper method, as each element of the output array contains
/// the name and the class the component belongs to locally. 
///
/// ComponentName must be Method or Parameter because those are the only two things that are inherited.
///
/// local is generated by getComponentList. you must (1) make a new $LIST. (2) pass into getComponentList with Method or Property
/// (3) pass that list into getInheritedComponents as local (by value)
ClassMethod getInheritedComponents(classPath As %String, componentName As %String, local As %List) As %DynamicArray
{
	  do ^%ZDocBookBoost
	  SET myquery = "SELECT ID1, Name FROM %Dictionary.Compiled"_componentName_" WHERE parent = '" _ classPath _ "'"
	  SET tStatement = ##class(%SQL.Statement).%New()
	  SET qStatus = tStatement.%Prepare(myquery)
	  SET rset = tStatement.%Execute()
	  SET toReturn = [] // creates a dynamic array
	  //zwrite "local is: "_local
	  	WHILE rset.%Next() {
	  		set compID = rset.Name
	  		if ($LISTFIND(local,compID) = 0) { // this component is inherited
	  			set object = {}
	  			set object.Name = rset.Name // TODO: we don't need the ID, right?
	  			set super = ##class(ClassDocAPI.v1.findSuperclass).findSuper(rset.ID1,componentName)
	  			set object.Super = super
	  			if (super '= "") { do toReturn.%Push(object) } // IMPORTANT: please refer to findSuperclass.findSuperHelper header comments to know what's going on here.
	  		}
	    }
	    return toReturn
}


/// main method of this class. returns a DynamicObject with all the relevant information. 
/// Edit the keywords for each type of component in the keywords from ROBJ section. It's called that because I just
/// copy pasted them from the docbook ROBJ section.
/// returns {} if class is hidden or can't find the class, or something went wrong (incorrect use of API)
ClassMethod generateClass(classPath As %String) As %DynamicObject
{
		// keywords from ROBJ
		set classKeywords = "GeneratedBy,Description,Abstract,ClassType,ClientDataType,ClientName,CompileAfter,DdlAllowed,DependsOn,Deprecated,Final,GeneratedBy,Hidden,Inheritance,Language,LegacyInstanceContext,NoExtent,OdbcType,Owner,ProcedureBlock,PropertyClass,ServerOnly,SoapBindingStyle,SoapBodyUse,SqlCategory,SqlRowIdName,SqlRowIdPrivate,SqlTableName,StorageStrategy,System,ViewQuery"
		set methodKeywords = "ReturnType,Description,Abstract,ClientName,CodeMode,Deprecated,ExternalProcName,Final,ForceGenerate,GenerateAfter,Internal,Language,NotInheritable,PlaceAfter,Private,ProcedureBlock,PublicList,ReturnResultsets,ServerOnly,SoapAction,SoapBindingStyle,SoapBodyUse,SoapMessageName,SoapNameSpace,SoapRequestMessage,SoapTypeNameSpace,SqlName,SqlProc,WebMethod"
		set parameterKeywords = "Type,Description,Abstract,Constraint,Deprecated,Final,Flags,Internal"
		set propertyKeywords = "Type,Description,Aliases,Calculated,Cardinality,ClientName,Collection,Deprecated,Final,Identity,InitialExpression,Internal,Inverse,MultiDimensional,OnDelete,Private,ReadOnly,Required,ServerOnly,SqlColumnNumber,SqlComputeCode,SqlComputed,SqlComputeOnChange,SqlFieldName,SqlListDelimiter,SqlListType,Transient"
		set queryKeywords = "Type,Description,ClientName,Final,Internal,Private,SoapBindingStyle,SoapBodyUse,SoapNameSpace,SqlName,SqlProc,SqlView,SqlViewName,WebMethod"
		set indexKeywords = "Description,Condition,Data,Extent,IdKey,Internal,PrimaryKey,SqlName,Type,Unique"
		set foreignkeyKeywords = "Description,Internal,NoCheck,OnDelete,OnUpdate,SqlName"
		set triggerKeywords = "Description,CodeMode,Event,Final,Foreach,Internal,Language,NewTable,OldTable,Order,SqlName,Time,UpdateColumnList"
		
		set classObject = ..getComponents(classPath, "Class", classKeywords)
		if (classObject.%ToJSON() = "{}") {return {}} ///TODO: throw appropriate exceptions?? trace this back to get components and catch accordingly
		set localMethods = $LISTBUILD()
		set classObject.Methods = {}
		set classObject.Methods.LocalMethods = ..getComponentList(classPath, "Method", methodKeywords, .localMethods)
		set classObject.Methods.InheritedMethods = ..getInheritedComponents(classPath, "Method", localMethods)
		set localProperties = $LISTBUILD()
		set classObject.Properties = {}
		set classObject.Properties.LocalProperties = ..getComponentList(classPath, "Property", propertyKeywords, .localProperties)
		set classObject.Properties.InheritedProperties = ..getInheritedComponents(classPath, "Property", localProperties)
		
		set classObject.Parameters = ..getComponentList(classPath, "Parameter", parameterKeywords,)
		set classObject.Queries = ..getComponentList(classPath, "Query", queryKeywords,)
		set classObject.Indicies = ..getComponentList(classPath, "Index", indexKeywords,)
		set classObject.ForeignKeys = ..getComponentList(classPath, "ForeignKey", foreignkeyKeywords,)
		set classObject.Triggers = ..getComponentList(classPath, "Trigger", triggerKeywords,)
		set classObject.Family = ##class(ClassDocAPI.v1.Utils).getFamilyOfClass(classPath)
		//write classObject.%ToJSON()
		return classObject
}

}

