package client;

import math_ops.*;
import mware_lib.NameService;
import mware_lib.ObjectBroker;

public class TestClientMain {
    public static void main(String[] args) {

        if(args.length != 2) {
            System.out.println("Usage TestClientMain <nameservice-host> <nameservice-port>");
            return;
        }
        String host = args[0];
        int port = Integer.valueOf(args[1]);

        ObjectBroker objectBroker = ObjectBroker.init(host, port, true);
        NameService nameService = objectBroker.getNameService();
        Object rawRef = nameService.resolve("zumsel");
        _CalculatorImplBase implBase = _CalculatorImplBase.narrowCast(rawRef);
        try {
            for (int i = 0; i < 100; i++) {
                double result = implBase.add(i, i);
                System.out.println(result);
            }
            String getStrResult = implBase.getStr(2);
            System.out.println(getStrResult);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
