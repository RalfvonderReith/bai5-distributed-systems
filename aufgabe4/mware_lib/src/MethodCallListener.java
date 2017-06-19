package mware_lib;

import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;

public class MethodCallListener implements Runnable {
	
	ServerSocket serverSocket;
	int port;
	private boolean running = false;
	private final NameService nameService;
	
	public MethodCallListener(int port, NameService nameService) {
		this.port = port;
		this.nameService = nameService;
	}
	
	private boolean initialize() {
		System.out.print("trying to set up server socket...");
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
					RequestHandler rh = new RequestHandler(serverSocket.accept(), nameService);
					new Thread(rh).start();
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
	
	public InetAddress getInetAddress() {
		return serverSocket.getInetAddress();
	}
	
	public int getPort() {
		return port;
	}
}