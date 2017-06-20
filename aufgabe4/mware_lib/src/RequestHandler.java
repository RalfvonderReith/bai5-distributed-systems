package mware_lib;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.Socket;

public class RequestHandler implements Runnable {
	
	private Socket socket;
	private ObjectInputStream ois;
	private ObjectOutputStream oos;
	private final NameService nameService;
	
	public RequestHandler(Socket socket, NameService nameService) {
		this.socket = socket;
		this.nameService = nameService;
	}
	
	private void initialize() throws IOException {
		ois = new ObjectInputStream(socket.getInputStream());
		oos = new ObjectOutputStream(socket.getOutputStream());
	}
	
	private void process() throws IOException, ClassNotFoundException {
	 	Object inputObj = ois.readObject();
	 	//expecting a string object containing a rebind or resolve message - if its not a string, its an unexpected message
		if(!(inputObj instanceof RmiObject)) {
			System.out.println("unexpected object");
			return;
		}
		RmiObject rmiObj = (RmiObject) inputObj;
		
		Dispatcher dp = (Dispatcher) nameService.resolve(rmiObj.refName());
		Object returnValue;
		try{
			returnValue = dp.call(rmiObj);
		} catch (Exception e) {
			returnValue = e;
		}
		oos.writeObject(returnValue);
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