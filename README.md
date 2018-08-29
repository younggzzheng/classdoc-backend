# classdoc-backend
REST API for ClassDoc backend written in ObjectScript for InterSystems Corporation

### The API
The backend is written in ObjectScript and uses %SQL.Statement to execute queries to pull class data from the %Dictionary class. This class data is processed in Querier into a %DynamicObject. Important to note is that Querier uses the automatically generated IsDefined() methods for each component of the class, so a class that does not have Abstract defined will not have an Abstract attribute. The complete object can be obtained by making a call to generateClass(classname). This DynamicObject is turned into a JSON string in REST.cls, where a call to generateClass is used as input to %ToJSON(). This string output is the output of the REST API.

Namespace is changed by changing the global ^ClassDocNamespace to "USER", or whatever your namespace is. ClassMethod changeNamespace(namespace) is in the REST class, and should be changed through a POST request to /TOC/:namespace.


### The JSON String
The object is structured as follows: A class has attributes of its own, such as name, description, abstract, etc., and it also has class components, listed as Methods, Parameters, Properties, Queries, Indicies, Foreign Keys, and Triggers.
It also has a family, which describes sibling packages and classes, and ancestor packages.

Each of the class components has it's own components, with Methods and Properties having subsections of Local/Inherited Methods and Local/Inherited Properties respectively. These special subobjects exist because Methods and Properties can be inherited from superclasses, and the API needs a way to differentiate between methods defined in the actual class itself and those inherited from its super classes.

Additional keywords can be added in generateClass. However, you must make sure that the IsDefined method exists for any additional keywords added. If they do not, you can add them in getComponents.  
