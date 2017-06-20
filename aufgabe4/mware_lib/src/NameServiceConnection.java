import mware_lib.ObjRef;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.InetAddress;
import java.net.Socket;

public class NameServiceConnection {
    private Socket socket;
    private ObjectInputStream ois;
    private ObjectOutputStream oos;
    private InetAddress rmiAddress;
    private int rmiPort;

    public NameServiceConnection(String host, int nsport, InetAddress rmiAddress, int rmiPort) throws IOException {
        System.out.println("NameServiceConnection");
        try (
                Socket socket = new Socket(InetAddress.getByName(host), nsport);
                ObjectOutputStream oos = new ObjectOutputStream(socket.getOutputStream());
                ObjectInputStream ois = new ObjectInputStream(socket.getInputStream())
        ) {
            this.socket = socket;
            this.ois = ois;
            this.oos = oos;
            this.rmiAddress = rmiAddress;
            this.rmiPort = rmiPort;
        }
        System.out.println("NameServiceConnection constructed");
    }

    public ObjRef sendResolve(String refName) throws IOException {
        oos.writeObject(refName);
        try {
            Object obj = ois.readObject();
            if (obj instanceof ObjRef) {
                return (ObjRef) obj;
            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }

    public void sendRebind(String ref) throws IOException {
        oos.writeObject(new ObjRef(ref, rmiPort, rmiAddress));
    }
}
