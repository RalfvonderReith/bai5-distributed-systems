package nameserver;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.InetAddress;
import java.net.Socket;

import mware_lib.ObjRef;

public class NameServerConnection implements Runnable {

	private static final int COMMAND = 0;
	private static final int REFNAME = 1;
	private static final int IP = 2;
	private static final int PORT = 3;
	
	private Socket socket;
	private ObjectInputStream ois;
	private ObjectOutputStream oos;

	private final NameServer nameServer;
	
	public NameServerConnection(Socket socket, NameServer nameServer) {
		this.socket = socket;
		this.nameServer = nameServer;
	}
	
	private void initialize() throws IOException {
		oos = new ObjectOutputStream(socket.getOutputStream());
		oos.flush();
		ois = new ObjectInputStream(socket.getInputStream());
	}
	
	private void process() throws IOException, ClassNotFoundException {
	 	Object inputObj = ois.readObject();
	 	//expecting a string object containing a rebind or resolve message - if its not a string, its an unexpected message
		if(!(inputObj instanceof String)) {
			System.out.println("unexpected object");
			return;
		}
		String inputString = (String) inputObj;
		String[] input = inputString.split("/");
		
		if (input[COMMAND].equals("rebind")) {
			String name = input[REFNAME];
			int port = Integer.parseInt(input[PORT]);
			String address = input[IP];
			nameServer.addReference(new ObjRef(name, port, address));
			System.out.println("rebinding ... "+name+" - "+address+":"+port);
		} else if(input[COMMAND].equals("resolve")) {
			String name = input[REFNAME];
			ObjRef ref = nameServer.getReference(name);
			oos.writeObject(ref);
			System.out.println("resolving "+name+"... "+ref.toString());
		} else {
			System.out.println("unexpected message");
		}
		
		//time outs?
	}
	
	@Override
	public void run() {
		try {
			initialize();
			System.out.println("connection established");
			process();
		} catch(IOException | ClassNotFoundException e) {
			e.printStackTrace();
		} finally {
			close();
		}
	}
	
	private void close() {
		try {
			if(ois != null) {
				ois.close();
			}
			if(oos != null) {
				oos.close();
			}
			socket.close();
		} catch(IOException e) {
			e.printStackTrace();
		}	
	}
}
