package idl_compiler;


/**
 * IDL compiler main class.
 *
 * @author  (c) H. Schulz, 2016
 * This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.
 * You may use and modify it as long as you state the above copyright.
 *
 */
public class IDLCompiler {
	public static final String NEWLINE = "\n";
	public static final String IDL_KEYWORD_INT = "int";
	public static final String IDL_KEYWORD_DOUBLE = "double";
	public static final String IDL_KEYWORD_STRING = "string";
	public static final String JAVA_INT = "int";
	public static final String JAVA_DOUBLE = "double";
	public static final String JAVA_STRING = "String";


	// Supported data types
	/**
	 * @author    (c) H. Schulz, 2016    This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.  You may use and modify it as long as you state the above copyright.
	 */
	public static enum SupportedDataTypes {
		/**
		 * @uml.property  name="iNT"
		 * @uml.associationEnd
		 */
		INT, /**
		 * @uml.property  name="dOUBLE"
		 * @uml.associationEnd
		 */
		DOUBLE,  /**
		 * @uml.property  name="sTRING"
		 * @uml.associationEnd
		 */
		STRING
	}

	/**
	 * Get string representation of supported IDL data type
	 *
	 * @param type
	 * @return
	 */
	public static String getSupportedIDLDataTypeName(SupportedDataTypes type) {
		switch (type) {
		case INT: return IDL_KEYWORD_INT;
		case DOUBLE: return IDL_KEYWORD_DOUBLE;
		case STRING: return IDL_KEYWORD_STRING;
		default: return null;
		}
	}

	/**
	 * Get string representation of data type
	 *
	 * @param type
	 * @return
	 */
	public static String getSupportedJavaDataTypeName(SupportedDataTypes type) {
		switch (type) {
		case INT: return JAVA_INT;
		case DOUBLE: return JAVA_DOUBLE;
		case STRING: return JAVA_STRING;
		default: return null;
		}
	}

	/**
	 * Get supported data type for given keyword.
	 * @param keyword
	 * @return
	 */
	public static SupportedDataTypes getSupportedTypeForKeyword(String keyword) {
		if (keyword.equals(IDL_KEYWORD_DOUBLE)) return SupportedDataTypes.DOUBLE;
		else if (keyword.equals(IDL_KEYWORD_INT)) return SupportedDataTypes.INT;
		else if (keyword.equals(IDL_KEYWORD_STRING)) return SupportedDataTypes.STRING;
		else return null;
	}


	/**
	 * Data container for method data.
	 * @author   (c) H. Schulz, 2016    This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.  You may use and modify it as long as you state the above copyright.
	 */
	static class MethodData {
		/**
		 * @uml.property  name="name"
		 */
		private String name;
		/**
		 * @uml.property  name="returnType"
		 */
		private SupportedDataTypes returnType;
		/**
		 * @uml.property  name="paramTypes"
		 * @uml.associationEnd  multiplicity="(0 -1)"
		 */
		private SupportedDataTypes[] paramTypes;
		private String[] paramNames;

		public MethodData(String name, SupportedDataTypes returnType, SupportedDataTypes[] paramTypes, String[] paramNames) {
			this.name = name;
			this.returnType = returnType;
			this.paramTypes = paramTypes;
			this.paramNames = paramNames;
		}

		/**
		 * @return
		 * @uml.property  name="name"
		 */
		public String getName() {
			return name;
		}

		/**
		 * @return
		 * @uml.property  name="returnType"
		 */
		public SupportedDataTypes getReturnType() {
			return returnType;
		}

		/**
		 * @return
		 * @uml.property  name="paramTypes"
		 */
		public SupportedDataTypes[] getParamTypes() {
			return paramTypes;
		}

		public String[] getParamNames() {
			return paramNames;
		}
	}

}
