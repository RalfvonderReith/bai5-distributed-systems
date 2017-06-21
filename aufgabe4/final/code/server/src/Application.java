

import java.util.Scanner;

public class Application {
    public static void main(String[] args) {
        String host = "localhost";
        int port = 15_000;

        ObjectBroker objectBroker = ObjectBroker.init(host, port, true);
        objectBroker.getNameService().rebind(new Calculator(), "calculator");

        System.out.println("Press a key to end the application.");
        Scanner scanner = new Scanner(System.in);
        scanner.next();

        objectBroker.shutdown();
    }
}
