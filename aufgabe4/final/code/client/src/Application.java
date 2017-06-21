
public class Application {
    public static void main(String[] args) {
        String host = "127.0.0.1";
        int port = 15000;

        ObjectBroker objectBroker = ObjectBroker.init(host, port, true);
        Object refObj = objectBroker.getNameService().resolve("calculator");

        System.out.println(refObj);
        
        _CalculatorImplBase wrapper = _CalculatorImplBase.narrowCast(refObj);
        try {
            System.out.println("result: "+wrapper.add(1, 2));
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            System.out.println("result: "+wrapper.div(0, 2));
        } catch (Exception e) {
        	System.out.println("received Exception: expected division by zero");
            e.printStackTrace();
        }

        try {
            System.out.println("result: "+wrapper.asString(10_012));
        } catch (Exception e) {
            e.printStackTrace();
        }

        objectBroker.shutdown();
    }
}
