import mware_lib.MethodCallListener;
import mware_lib.NameService;
import mware_lib.NameServiceImpl;

/**
 * - mutable
 *
 * @param
 * @return
 */
public class ObjectBroker {
	private static final int PORT_DEFAULT = 15001;
    private final NameServiceImpl nameService;
    
    private ObjectBroker(String host, int port, boolean debug) {
        nameService = new NameServiceImpl(host, port, debug);
        MethodCallListener mcl = new MethodCallListener(PORT_DEFAULT, nameService);
        nameService.initialize(mcl.getPort(), mcl.getInetAddress());
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
