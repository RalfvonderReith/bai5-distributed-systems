package main;

import java.util.ArrayList;

/**
 * @author   (c) H. Schulz, 2016    This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.  You may use and modify it as long as you state the above copyright.
 */
public class IDLmodule {
	// this module's name
	private String moduleName;

	// container of classes defined in this module
	private ArrayList<IDLclass> IDLclasses;
	
	public IDLmodule(String name) {
		this.moduleName = name;
		IDLclasses = new ArrayList<IDLclass>();
	}
	
	public void addClass(IDLclass newClass) {
		IDLclasses.add(newClass);
	}

	public String getModuleName() {
		return moduleName;
	}

	public IDLclass[] getClasses() {
		IDLclass classes[] = new IDLclass[IDLclasses.size()];
		IDLclasses.toArray(classes);
		return classes;
	}
}
