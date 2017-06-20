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
        initialize();
    }

    private void initialize() {
        System.out.print("trying to set up server socket on port "+port+"...");
        try {
            serverSocket = new ServerSocket(port);
            running = true;
            System.out.println("Success!");
        } catch (IOException e) {
        	System.out.println("Fail!");
            throw new IllegalStateException(e);
        }
        
    }

    @Override
    public void run() {
        while (running) {
            System.out.println("waiting for incoming connection...");
            try {
                RequestHandler rh = new RequestHandler(serverSocket.accept(), nameService);
                new Thread(rh).start();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        try {
            serverSocket.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public InetAddress getInetAddress() {
        return serverSocket.getInetAddress();
    }

    public int getPort() {
        return port;
    }
}