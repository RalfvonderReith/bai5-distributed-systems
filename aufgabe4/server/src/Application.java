package server.src;

import mware_lib.ObjectBroker;

public class Application {
    public static void main(String[] args) {
        String host = "";
        int port = 15_000;

        ObjectBroker objectBroker = ObjectBroker.init(host, port, true);
        objectBroker.getNameService().rebind(new Calculator(), "calculator");
        objectBroker.shutdown();
    }
}
