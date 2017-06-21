import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.Socket;

public class NameServerConnection implements Runnable {

	private static final int COMMAND = 0;
	private static final int REFNAME = 1;
	private static final int IP = 2;
	private static final int PORT = 3;
	
	private Socket socket;
	private ObjectInputStream ois;
	private ObjectOutputStream oos;
	
	private final Log logger;

	private final NameServer nameServer;
	
	public NameServerConnection(Socket socket, NameServer nameServer, Log logger) {
		this.logger = logger;
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
			logger.write("unexpected object");
			return;
		}
		String inputString = (String) inputObj;
		String[] input = inputString.split("/");
		
		if (input[COMMAND].equals("rebind")) {
			String name = input[REFNAME];
			int port = Integer.parseInt(input[PORT]);
			String address = input[IP];
			nameServer.addReference(new ObjRef(name, port, address));
			logger.write("rebinding ... "+name+" - "+address+":"+port);
		} else if(input[COMMAND].equals("resolve")) {
			String name = input[REFNAME];
			ObjRef ref = nameServer.getReference(name);
			oos.writeObject(ref);
			logger.write("resolving "+name+"... "+ref.toString());
		} else {
			logger.write("unexpected message");
		}
		
		//time outs?
	}
	
	@Override
	public void run() {
		try {
			initialize();
			logger.write("connection established");
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
