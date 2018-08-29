/// Utility class used to find the superclass of an inherited method or property.
Class ClassDocAPI.v1.findSuperclass
{
/// find super is given a ID and a type. ID is the ID taken from compiledmethod or compiledproperty.
/// type must be exactly "Method" or "Property".
ClassMethod findSuper(ID As %String, type As %String) As %String
{
 	 set classPath = $PIECE(ID,"||",1) // pull out the class path
 	 return ..findSuperHelper(ID,$LISTBUILD(classPath),type)
}

///	methodID: ID of method you're trying to search for. same each call.
///	superClassesList: The list of superclasses that you're searching through
///	type: this must be exactly "Method" or "Property", indicating what type you're looking for the super of.
///	
///	returns: the name of the super class, unless if it doesn't exist, or is a generated one, like <PropertyName>LogicalToDisplay
///	If doesn't exist, then it'll return the empty string.
///	
///	IMPORTANT NOTE: I am returning the empty string so we have some method of identifying methods like LogicalToDisplay, who don't actually
///	have superclasses. This way, if you realize that findSuper returns an empty string one of two things must've happened: 
///		(1) the API caller typed in an incorrect input for the method name. If this is the case, no exception will be thrown, just an empty string.
///		(2) the method is actually an autogenerated parent-less method (side-inherited as Joel Solon likes to call them). Generally, people do not want to
///				see these methods, and this is the only good way of telling what they are. When setting the super attribute in generateClass, I
///				will check to see if the super is an empty string, if it is, then throw out the entire inherited method because it's parentless and sideinherited.
	
ClassMethod findSuperHelper(methodID As %String, superClassesList, type As %String) As %String
{
		do ^%ZDocBookBoost
		new $namespace
		if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
		set $namespace = ^ClassDocNamespace
		/* first, check to see if the direct super classes contain this method. */
		set queue = $LB()
	    for i=1:1:$LISTLENGTH(superClassesList) {
	    	set className = $LIST(superClassesList, i)
	    	if (..matches(methodID, className, type)) {return className}
	    	
	    	/* add each class's superclasses to a queue for next iteration */
			set classObj =  ##class(%Dictionary.ClassDefinition).%OpenId(className, 0)
			/* If we hit a %Library class, like %Persistent, we need to add %Library in front of it and try. */
			if (classObj = "") {
				set className = "%Library."_$piece(className,"%",2)
				set classObj =  ##class(%Dictionary.ClassDefinition).%OpenId(className,0)
				/* If even after we've tried %Library and we still can't open the object, we were given a bogus or inaccessible className*/
				if (classObj = "") {return ""/*$$$ERROR("Method: " _ methodID _ " cannot be accessed or class name: " _ className _ " is bogus")*/}
	 		}
			set superClasses = $LISTFROMSTRING(classObj.Super, ",")
			for j=1:1:$LISTLENGTH(superClasses) {
				if (queue = $LB()) {	// we have this if statement here because first time adding needs to use *, subsequent times must use *+1
					set $LIST(queue,*) = $LIST(superClasses, j)
				} else {
				set $LIST(queue,*+1) = $LIST(superClasses, j)  // add into the queue one at a time. 
				}
			}
	    }
	    if ($LISTSAME(queue,$LB())) { return ""/*$$$ERROR("Method: " _ methodID _ " does not exist")*/ }
	    /* direct super classes did not match. must look to super super classes.*/
		return ..findSuperHelper(methodID, queue,type)  // pass in the queue as next level of classes to search.
}

/// returns 1 if className is the direct parent of methodID. 0 otherwise
ClassMethod matches(methodID As %String, className As %String, type As %String)
{
	new $namespace
	if (^ClassDocNamespace = "") {set ^ClassDocNamespace = "%SYS"}
	set $namespace = ^ClassDocNamespace
	do ^%ZDocBookBoost
	 set methodName = $PIECE(methodID,"||",2) // pull out the method name 
 	 set id = className _ "||" _ methodName
 	 if (type = "Method") {
 	 	&sql(SELECT ID FROM %Dictionary.MethodDefinition WHERE ID = :id)
 	 } else { 
 	 	if (type = "Property") {
 	 		&sql(SELECT ID FROM %Dictionary.PropertyDefinition WHERE ID = :id)
 	 	} else {
 	 		return 0
 	 		}
 	 	}
 	 if (SQLCODE = 0) {return 1} else {return 0}
}


}
