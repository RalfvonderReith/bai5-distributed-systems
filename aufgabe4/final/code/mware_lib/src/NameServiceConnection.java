package mware_lib;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.InetAddress;
import java.net.Socket;

public class NameServiceConnection {
    private Socket socket;
    private ObjectInputStream ois;
    private ObjectOutputStream oos;
    private String rmiAddress;
    private int rmiPort;

    public NameServiceConnection(String host, int nsport, String inetAddress, int rmiPort, Log logger) {
        logger.write("establishing NameServiceConnection");
        try {
            socket = new Socket(InetAddress.getByName(host), nsport);
            oos = new ObjectOutputStream(socket.getOutputStream());
            oos.flush();
            ois = new ObjectInputStream(socket.getInputStream());
            this.rmiAddress = inetAddress;
            this.rmiPort = rmiPort;
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
        logger.write("Success!");
    }

    public String sendResolve(String refName) throws IOException {
        oos.writeObject("resolve/"+refName);
        try {
            Object obj = ois.readObject();
            System.out.println(obj);
            if (obj instanceof String) {
                return (String) obj;
            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }

    public void sendRebind(String ref) throws IOException {
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
