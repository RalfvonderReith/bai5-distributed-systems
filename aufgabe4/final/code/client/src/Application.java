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
