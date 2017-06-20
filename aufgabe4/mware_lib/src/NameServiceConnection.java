package mware_lib;
<<<<<<< HEAD

import mware_lib.ObjRef;
=======
>>>>>>> 5f3641ad89ba0a84bbed4aacb6e6b43b0ac60004

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

    public NameServiceConnection(String host, int nsport, InetAddress rmiAddress, int rmiPort) {
        System.out.println("NameServiceConnection");
        try {
            socket = new Socket(InetAddress.getByName(host), nsport);
            oos = new ObjectOutputStream(socket.getOutputStream());
            ois = new ObjectInputStream(socket.getInputStream());
            this.rmiAddress = rmiAddress;
            this.rmiPort = rmiPort;
        } catch (IOException e) {
            throw new IllegalStateException(e);
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
    	System.out.println(rmiAddress.toString());
        oos.writeObject("rebind/"+ref+"/"+rmiAddress.toString()+"/"+rmiPort);
    }

    public void shutdown() {
    	try {
			oos.close();
	    	ois.close();
	    	socket.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
    }
}
