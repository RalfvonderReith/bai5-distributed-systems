import mware_lib.NameService;
import mware_lib.RequestHandler;

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
        System.out.print("trying to set up server socket...");
        try {
            serverSocket = new ServerSocket(port);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
        System.out.println("Success!");
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