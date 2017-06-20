package mware_lib;

/**
 * - mutable
 *
 * @param
 * @return
 */
public class ObjectBroker {
	private static final int PORT_DEFAULT = 15003;
	private static final String INET_ADDRESS = "127.0.0.1";
    private final NameServiceImpl nameService;
    
    private ObjectBroker(String host, int port, boolean debug) {
        nameService = new NameServiceImpl(host, port, debug);
        MethodCallListener mcl = new MethodCallListener(PORT_DEFAULT, nameService);
        nameService.initialize(PORT_DEFAULT, INET_ADDRESS);
        new Thread(mcl).start();
    }

    public static ObjectBroker init(String host, int port, boolean debug) {
        return new ObjectBroker(host, port, debug);
    }

    public NameService getNameService() {
        return nameService;
    }

    public void shutdown() {

    }
}
