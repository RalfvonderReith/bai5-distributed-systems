

import java.util.Scanner;

import mware_lib.ObjectBroker;

public class Application {
    public static void main(String[] args) {
    	if (args == null || args.length != 2) {
    		System.out.println("no params given");
    		System.out.println("expected params : <ip> <port>");
    		return;
    	}
    	
        String host = args[0];
        int port = Integer.parseInt(args[1]);

        ObjectBroker objectBroker = ObjectBroker.init(host, port, true);
        objectBroker.getNameService().rebind(new Calculator(), "calculator");

        System.out.println("Press a key to end the application.");
        Scanner scanner = new Scanner(System.in);
        scanner.next();

        objectBroker.shutdown();
    }
}
