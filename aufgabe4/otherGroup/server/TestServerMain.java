package server;

import math_ops.Calculator;
import mware_lib.NameService;
import mware_lib.ObjectBroker;

public class TestServerMain {
    public static void main(String[] args) {

        if(args.length != 2) {
            System.out.println("Usage TestClientMain <nameservice-host> <nameservice-port>");
            return;
        }
        String host = args[0];
        int port = Integer.valueOf(args[1]);

        ObjectBroker objectBroker = ObjectBroker.init(host, port, false);
        NameService nameService = objectBroker.getNameService();
        Calculator calculator = new Calculator();
        nameService.rebind(calculator, "zumsel");
        // TODO: start receiver here
        //objectBroker.shutDown();
    }
}
