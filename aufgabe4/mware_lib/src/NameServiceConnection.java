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
    InetAddress rmiAddress;
    int rmiPort;

    public static NameServiceConnection connect(InetAddress nsip, int nsport, InetAddress rmiAddress, int rmiPort) {
        NameServiceConnection nsc = new NameServiceConnection();
        if(nsc.initialize(nsip, nsport, rmiAddress, rmiPort)) {
            return nsc;
        }
        return null;
    }

    private NameServiceConnection() {}

    private boolean initialize(InetAddress ip, int port, InetAddress rmiAddress, int rmiPort) {
        try {
            socket = new Socket(ip, port);
            this.rmiAddress = rmiAddress;
            this.rmiPort = rmiPort;
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

    public void sendRebind(String ref) throws IOException {
        oos.writeObject(new ObjRef(ref, rmiPort, rmiAddress));
    }
}
