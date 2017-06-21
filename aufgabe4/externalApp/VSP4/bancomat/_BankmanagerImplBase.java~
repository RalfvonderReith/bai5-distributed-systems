package bancomat;

import java.net.Socket;
import java.io.*;
import mware_lib.RmiObject;

public abstract class _BankmanagerImplBase {
    public abstract String getAccountID(int key) throws Exception;

    public static _BankmanagerImplBase narrowCast(Object refObj) {
        String[] refObjParts = ((String) refObj).split("/");
        return new Bankmanager(refObjParts[0], refObjParts[1], Integer.parseInt(refObjParts[2]));
    }

    private static class Bankmanager extends _BankmanagerImplBase{
        private final String refName;
        private final String host;
        private final int ping;

        private Bankmanager(String refName, String host, int ping) {
            this.refName = refName;
            this.host = host;
            this.ping = ping;
        }

        public String getAccountID(int key) throws Exception {
            Serializable params[] = {key};
            Class<?> paramTypes[] = {int.class};
            Object result = send(new RmiObject(refName, "getAccountID", params, paramTypes));
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