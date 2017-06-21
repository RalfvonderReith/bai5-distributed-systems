package main;


/**
 * @author   (c) H. Schulz, 2016    This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.  You may use and modify it as long as you state the above copyright.
 */
public class IDLclass {
	// module name where this class resides
	private String moduleName;
	// this (IDL-)class's name
	private String className;
	// methods of this class
	private IDLCompiler.MethodData methods[];

	public IDLclass(String name, String module, IDLCompiler.MethodData methods[]) {
		this.className = name;
		this.moduleName = module;
		this.methods = methods;
	}
	
	public String getModuleName() {
		return moduleName;
	}

	public String getClassName() {
		return className;
	}
	
	public IDLCompiler.MethodData[] getMethods() {
		return methods;
	}
}
