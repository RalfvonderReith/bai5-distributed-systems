package mware_lib;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.Socket;

public class RequestHandler implements Runnable {
	
	private Socket socket;
	private ObjectInputStream ois;
	private ObjectOutputStream oos;
	private final NameServiceImpl nameService;
	private final Log logger;
	
	public RequestHandler(Socket socket, NameServiceImpl nameService, Log logger) {
		this.logger = logger;
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
			logger.write("unexpected object");
			return;
		}
		RmiObject rmiObj = (RmiObject) inputObj;
		
		logger.write("received Rmicall for "+rmiObj.refName());
		
		Dispatcher dp = (Dispatcher) nameService.getReference(rmiObj.refName());
		Object returnValue;
		
		logger.write("resolved rmicall reference to: "+dp.toString());
		
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
