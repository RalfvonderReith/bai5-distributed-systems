import nameserver.NameServer;
import nameserver.NameServerConnection;

import java.io.IOException;
import java.net.ServerSocket;

public class NameServerListener implements Runnable {

	private ServerSocket serverSocket;
	private int port;
	private NameServer nameServer;
	private boolean running = false;
	
	NameServerListener(int port, NameServer nameServer) {
		this.port = port;
		this.nameServer = nameServer;
	}
	
	private boolean initialize() {
		System.out.print("trying to set up server Socket...");
		try {
			serverSocket = new ServerSocket(port);
		} catch(IOException e) {
			e.printStackTrace();
			return false;
		}
		System.out.println("Success!");
		return true;
	}
	
	@Override
	public void run() {
		running = initialize();
		if(running) {
			while(running) {
				System.out.println("waiting for incoming connection...");
				try {
					NameServerConnection nsc = new NameServerConnection(serverSocket.accept(), nameServer);
					new Thread(nsc).start();
				} catch(Exception e) {
					e.printStackTrace();
				}
			}
			try {
				serverSocket.close();
			} catch(IOException e) {
				e.printStackTrace();
			}
		}
	}
}
