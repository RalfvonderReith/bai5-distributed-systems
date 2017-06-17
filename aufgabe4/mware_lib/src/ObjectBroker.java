package mware_lib;

/**
 * - mutable
 *
 * @param
 * @return
 */
public class ObjectBroker {
    private final NameService nameService;

    private ObjectBroker(String host, int port, boolean debug) {
        nameService = new NameServiceImpl(host, port, debug);
    }

    public static ObjectBroker init(String host, int port, boolean debug) {
        return new ObjectBroker(host, port, debug);
    }

    public NameService getNameService() {
        return nameService;
    }

    public void shutdown() {}
}
