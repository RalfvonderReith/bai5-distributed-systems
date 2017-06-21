import java.net.Socket;
import java.io.*;

public abstract class _CalculatorImplBase {
    public abstract int add(int a, int b) throws Exception;
    public abstract double div(int a, int b) throws Exception;
    public abstract String asString(int a) throws Exception;

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

        public int add(int a, int b) throws Exception {
            Serializable params[] = {a, b};
            Class<?> paramTypes[] = {int.class, int.class};
            Object result = send(new RmiObject(refName, "add", params, paramTypes));
            if (result instanceof Exception) throw new Exception((Exception) result);
            return (int) result;
        }

        public double div(int a, int b) throws Exception {
            Serializable params[] = {a, b};
            Class<?> paramTypes[] = {int.class, int.class};
            Object result = send(new RmiObject(refName, "div", params, paramTypes));
            if (result instanceof Exception) throw new Exception((Exception) result);
            return (double) result;
        }

        public String asString(int a) throws Exception {
            Serializable params[] = {a};
            Class<?> paramTypes[] = {int.class};
            Object result = send(new RmiObject(refName, "asString", params, paramTypes));
            if (result instanceof Exception) throw new Exception((Exception) result);
            return (String) result;
        }

        private Object send(RmiObject rmiObject) {
            try {
                Socket socket = new Socket(host, ping);
                ObjectOutputStream outStream = new ObjectOutputStream(socket.getOutputStream());
                outStream.flush();
                ObjectInputStream inStream = new ObjectInputStream(socket.getInputStream());
                outStream.writeObject(rmiObject);
                

                outStream.close();
                inStream.close();
                return inStream.readObject();
            } catch (IOException | ClassNotFoundException e) {
                return e;
            }
        }
    }

}