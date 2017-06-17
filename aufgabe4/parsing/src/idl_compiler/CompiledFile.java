package idl_compiler;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.ObjectInput;
import java.util.Arrays;
import java.util.Collections;
import java.util.stream.Collectors;

/**
 * This class creates the compiled file, containing the java source code.
 */
public class CompiledFile {
    private static final String TAB1 = "    ";
    private static final String TAB2 = TAB1 + TAB1;
    private static final String TAB3 = TAB2 + TAB1;
    private static final String TAB4 = TAB3 + TAB1;
    private static final String TAB5 = TAB4 + TAB1;

    public CompiledFile(IDLmodule module, String name) {
        new File(name + ".java").delete();

        try (FileWriter fileWriter = new FileWriter(name + ".java", true)) {
            fileWriter.write(head(module.getModuleName()));

            for (IDLclass clazz : module.getClasses()) {
                fileWriter.write(abstractClassHead(clazz.getClassName()));
                fileWriter.write(" {\n");
                fileWriter.write(abstractMethods(clazz.getMethods()));
                fileWriter.write(narrowCast(clazz.getClassName()));
                fileWriter.write("\n\n");
                fileWriter.write(wrapperClass(clazz.getClassName(), clazz.getMethods()));
                fileWriter.write("\n}");
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /*------------------------------------------------------------------------------------------------------------------
    private helper (abstract class)
    ------------------------------------------------------------------------------------------------------------------*/
    private String head(String moduleName) {
        return
                "package " + moduleName + ";\n\n" +
                        "import java.net.Socket;\n" +
                        "import java.io.*;\n" +
                        "import mware_lib.RmiObject;\n\n";
    }

    private String abstractClassHead(String className) {
        return "public abstract class _" + className + "ImplBase";
    }

    private String abstractMethods(IDLCompiler.MethodData methods[]) {
        StringBuilder result = new StringBuilder();
        for (IDLCompiler.MethodData method : methods) {
            result
                    .append(
                            abstractMethodHead(
                                    IDLCompiler.getSupportedJavaDataTypeName(method.getReturnType()),
                                    method.getName(),
                                    params(method.getParamNames(), method.getParamTypes())
                            ));
        }

        return result.append("\n").toString();
    }

    private String params(String[] paramNames, IDLCompiler.SupportedDataTypes[] paramTypes) {
        if (paramNames.length != paramTypes.length) throw new IllegalArgumentException(
                "paramNames amount: " + paramNames.length + ", paramTypes amount: " + paramTypes.length
        );

        StringBuilder result = new StringBuilder();
        for (int i = 0; i < paramNames.length; i++) {
            result
                    .append(IDLCompiler.getSupportedJavaDataTypeName(paramTypes[i]))
                    .append(" ")
                    .append(paramNames[i])
                    .append(", ");
        }
        if (result.length() > 0) return result.substring(0, result.length() - 2); // to delete the last ", "
        return result.toString();
    }

    private String abstractMethodHead(String returnType, String name, String params) {
        return TAB1 + "public abstract " + returnType + " " + name + "(" + params + ") throws Exception;\n";
    }

    private String narrowCast(String className) {
        return TAB1 + "public static _" + className + "ImplBase narrowCast(Object refObj) {\n"
                + TAB2 + "String[] refObjParts = ((String) refObj).split(\"/\");\n"
                + TAB2 + "return new Calculator(refObjParts[0], refObjParts[1], Integer.parseInt(refObjParts[2]));\n"
                + TAB1 + "}";
    }

    /*------------------------------------------------------------------------------------------------------------------
    private helper (wrapper class)
    ------------------------------------------------------------------------------------------------------------------*/
    private String wrapperClass(String className, IDLCompiler.MethodData[] methods) {
        return classHead(className) + "{\n" +
                variables() +
                constructor() +
                methods(methods) +
                sendMethod() +
                TAB1 + "}\n";
    }

    private String variables() {
        return TAB2 + "private final String refName;\n"
                + TAB2 + "private final String host;\n"
                + TAB2 + "private final int ping;\n\n";
    }

    private String constructor() {
        return TAB2 + "private Calculator(String refName, String host, int ping) {\n"
                + TAB3 + "this.refName = refName;\n"
                + TAB3 + "this.host = host;\n"
                + TAB3 + "this.ping = ping;\n"
                + TAB2 + "}\n";
    }

    private String classHead(String className) {
        return TAB1 + "private static class " + className + " extends _" + className + "ImplBase";
    }

    private String methods(IDLCompiler.MethodData[] methods) {
        StringBuilder result = new StringBuilder();
        for (IDLCompiler.MethodData method : methods) {
            result.append(method(method));
        }

        return result.append("\n").toString();
    }

    private String method(IDLCompiler.MethodData method) {
        String returnType = IDLCompiler.getSupportedJavaDataTypeName(method.getReturnType());
        String paramNames = commaArrayString(method.getParamNames());
        String paramTypes = commaArrayString(
                Arrays.stream(method.getParamTypes()).map(
                        elem -> IDLCompiler.getSupportedJavaDataTypeName(elem) + ".class"
                ).toArray()
        );

        return "\n" + methodHead(returnType, method.getName(), params(method.getParamNames(), method.getParamTypes())) + " {\n"
                + TAB3 + "Serializable[] params = {" + paramNames + "};\n"
                + TAB3 + "Class<?>[] paramTypes = {" + paramTypes + "};\n"
                + TAB3 + "Object result = send(new RmiObject(refName, \"" + method.getName() + "\", params, paramTypes));\n"
                + TAB3 + "if (result instanceof Exception) throw new Exception((Exception) result);\n"
                + TAB3 + "return (" + returnType + ") result;\n"
                + TAB2 + "}\n";
    }

    private String methodHead(String returnType, String name, String params) {
        return TAB2 + "public " + returnType + " " + name + "(" + params + ") throws Exception";
    }

    private String commaArrayString(Object[] paramNames) {
        StringBuilder result = new StringBuilder();
        for (Object paramName : paramNames) {
            result.append(paramName).append(", ");
        }
        if (result.length() > 0) return result.substring(0, result.length() - 2); // to delete the last ", "
        return result.toString();
    }

    private String sendMethod() {
        return TAB2 + "private Object send(RmiObject rmiObject) throws IOException, ClassNotFoundException {\n"
                + TAB3 + "try (\n"
                + TAB5 + "Socket socket = new Socket(host, ping);\n"
                + TAB5 + "ObjectInputStream inStream = new ObjectInputStream(socket.getInputStream());\n"
                + TAB5 + "ObjectOutputStream outStream = new ObjectOutputStream(socket.getOutputStream());\n"
                + TAB3 + ") {\n"

                + TAB4 + "outStream.writeObject(rmiObject);\n"
                + TAB4 + "return inStream.readObject();\n"
                + TAB3 + "}\n"
                + TAB2 + "}\n";
    }
}
