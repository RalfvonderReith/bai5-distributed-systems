package mware_lib;

import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;

public class MethodCallListener implements Runnable {

    ServerSocket serverSocket;
    int port;
    private boolean running = false;
    private final NameServiceImpl nameService;
    private final Log logger;

    public MethodCallListener(int port, NameServiceImpl nameService, Log logger) {
        this.port = port;
        this.nameService = nameService;
        this.logger = logger;
        initialize();
    }

    private void initialize() {
    	logger.write("trying to set up server socket on port "+port+"...");
        try {
            serverSocket = new ServerSocket(port);
            running = true;
            logger.write("Success!");
        } catch (IOException e) {
        	logger.write("Fail!");
            throw new IllegalStateException(e);
        }
        
    }

    @Override
    public void run() {
        while (running) {
        	logger.write("waiting for incoming connection...");
            try {
                RequestHandler rh = new RequestHandler(serverSocket.accept(), nameService, logger);
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