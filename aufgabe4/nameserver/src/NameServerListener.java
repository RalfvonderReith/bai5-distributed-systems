package nameserver;

import java.io.IOException;
import java.net.ServerSocket;

import mware_lib.Log;

public class NameServerListener implements Runnable {

	private ServerSocket serverSocket;
	private int port;
	private NameServer nameServer;
	private boolean running = false;
	private final Log logger;
	
	NameServerListener(int port, NameServer nameServer, Log logger) {
		this.logger = logger;
		this.port = port;
		this.nameServer = nameServer;
	}
	
	private boolean initialize() {
		logger.write("trying to set up server Socket...");
		try {
			serverSocket = new ServerSocket(port);
		} catch(IOException e) {
			e.printStackTrace();
			return false;
		}
		logger.write("Success!");
		return true;
	}
	
	@Override
	public void run() {
		running = initialize();
		if(running) {
			while(running) {
				logger.write("waiting for incoming connection...");
				try {
					NameServerConnection nsc = new NameServerConnection(serverSocket.accept(), nameServer, logger);
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
