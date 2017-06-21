package math_ops;

import java.net.Socket;
import java.io.*;
import mware_lib.RmiObject;

public abstract class _CalculatorImplBase {
    public abstract double add(double a, double b) throws Exception;
    public abstract String getStr(double a) throws Exception;

    public static _CalculatorImplBase narrowCast(Object refObj) {
        String[] refObjParts = ((String) refObj).split("/");
        return new Calculator(refObjParts[0], refObjParts[1], Integer.parseInt(refObjParts[2]));
    }

    private static class Calculator extends _CalculatorImplBase{
        private final String refName;
        private final String host;
        private final int ping;

        private Calculator(String refName, String host, int ping) {
            this.refName = refName;
            this.host = host;
            this.ping = ping;
        }

        public double add(double a, double b) throws Exception {
            Serializable params[] = {a, b};
            Class<?> paramTypes[] = {double.class, double.class};
            Object result = send(new RmiObject(refName, "add", params, paramTypes));
            if (result instanceof Exception) throw new Exception((Exception) result);
            return (double) result;
        }

        public String getStr(double a) throws Exception {
            Serializable params[] = {a};
            Class<?> paramTypes[] = {double.class};
            Object result = send(new RmiObject(refName, "getStr", params, paramTypes));
            if (result instanceof Exception) throw new Exception((Exception) result);
            return (String) result;
        }

        private Object send(RmiObject rmiObject) {
            try(Socket socket = new Socket(host, ping)) {
                ObjectOutputStream outStream = new ObjectOutputStream(socket.getOutputStream());
                outStream.flush();
                ObjectInputStream inStream = new ObjectInputStream(socket.getInputStream());
                outStream.writeObject(rmiObject);
                

                Object resultObj = inStream.readObject();
                outStream.close();
                inStream.close();
                return resultObj;
            } catch (IOException | ClassNotFoundException e) {
                return e;
            }
        }
    }

}