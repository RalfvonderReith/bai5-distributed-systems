import mware_lib.ObjectBroker;
import server.src.Calculator;

public class Application {
    public static void main(String[] args) {
        String host = "localhost";
        int port = 14_001;

        ObjectBroker objectBroker = ObjectBroker.init(host, port, true);
        objectBroker.getNameService().rebind(new Calculator(), "calculator");
        objectBroker.shutdown();
    }
}
