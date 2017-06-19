package mware_lib;

/**
 * - mutable
 *
 * @param
 * @return
 */
public class ObjectBroker {
	private static final int PORT_DEFAULT = 5001;
    private final NameServiceImpl nameService;
    private final MethodCallListener mcl;
    
    private ObjectBroker(String host, int port, boolean debug) {
        nameService = new NameServiceImpl(host, port, debug);
        mcl = new MethodCallListener(PORT_DEFAULT, nameService);
        nameService.initialize(mcl.getPort(), mcl.getInetAddress());
    }

    public static ObjectBroker init(String host, int port, boolean debug) {
        return new ObjectBroker(host, port, debug);
    }

    public NameService getNameService() {
        return nameService;
    }

    public void shutdown() {}
}
