package bancomat;

import java.net.Socket;
import java.io.*;
import mware_lib.RmiObject;

public abstract class _AccountImplBase {
    public abstract double deposit(double param0) throws Exception;
    public abstract double withdraw(double param0) throws Exception;

    public static _AccountImplBase narrowCast(Object refObj) {
        String[] refObjParts = ((String) refObj).split("/");
        return new Account(refObjParts[0], refObjParts[1], Integer.parseInt(refObjParts[2]));
    }

    private static class Account extends _AccountImplBase{
        private final String refName;
        private final String host;
        private final int ping;

        private Account(String refName, String host, int ping) {
            this.refName = refName;
            this.host = host;
            this.ping = ping;
        }

        public double deposit(double param0) throws Exception {
            Serializable params[] = {param0};
            Class<?> paramTypes[] = {double.class};
            Object result = send(new RmiObject(refName, "deposit", params, paramTypes));
            if (result instanceof Exception) throw new Exception((Exception) result);
            return (double) result;
        }

        public double withdraw(double param0) throws Exception {
            Serializable params[] = {param0};
            Class<?> paramTypes[] = {double.class};
            Object result = send(new RmiObject(refName, "withdraw", params, paramTypes));
            if (result instanceof Exception) throw new Exception((Exception) result);
            return (double) result;
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