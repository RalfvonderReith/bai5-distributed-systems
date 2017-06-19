package mware_lib;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.InetAddress;
import java.net.Socket;

public class NameServiceConnection {

    Socket socket;
    ObjectInputStream ois;
    ObjectOutputStream oos;

    public static NameServiceConnection connect(InetAddress ip, int port) {
        NameServiceConnection nsc = new NameServiceConnection();
        if(nsc.initialize(ip, port)) {
            return nsc;
        }
        return null;
    }

    private NameServiceConnection() {

    }

    private boolean initialize(InetAddress ip, int port) {
        try {
            socket = new Socket(ip, port);
            ois = new ObjectInputStream(socket.getInputStream());
            oos = new ObjectOutputStream(socket.getOutputStream());
        } catch(IOException e) {
            e.printStackTrace();
        }
        return false;
    }

    public ObjRef sendResolve(String refName) throws IOException {
        oos.writeObject(refName);
        try {
            Object obj = ois.readObject();
            if(obj instanceof ObjRef) {
                return (ObjRef) obj;
            }
        } catch(ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }

    public void sendRebind(ObjRef ref) throws IOException {
        oos.writeObject(ref);
    }
}
