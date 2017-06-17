package client;

import compiled._CalculatorImplBase;
import mware_lib.ObjectBroker;
import server.src.Calculator;

public class Application {
    public static void main(String[] args) {
        String host = "";
        int port = 15_000;

        ObjectBroker objectBroker = ObjectBroker.init(host, port, true);
        Object refObj = objectBroker.getNameService().resolve("calculator");

        _CalculatorImplBase wrapper = _CalculatorImplBase.narrowCast(refObj);
        try {
            wrapper.add(1, 2);
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            wrapper.div(0, 2);
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            wrapper.asString(10_012);
        } catch (Exception e) {
            e.printStackTrace();
        }

        objectBroker.shutdown();
    }
}
