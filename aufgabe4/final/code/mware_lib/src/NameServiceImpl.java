package mware_lib;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class NameServiceImpl extends NameService {

    private Map<String, Dispatcher> referenceMap = new ConcurrentHashMap<>();
    private Log logger;
    private NameServiceConnection nsc;
    
    @SuppressWarnings("unused")
	private boolean debug = false;
    
    private String host;
    private int port;

    NameServiceImpl(String host, int port, boolean debug) {
    	this.port = port;
    	this.host = host;
        this.debug = debug;
    }
    
    public void initialize(int rmiPort, String inetAddress, Log logger) {
    	this.logger = logger;
    	logger.write("Starting NameService...");
        nsc = new NameServiceConnection(host, port, inetAddress, rmiPort, logger);
        logger.write("Success!");
    }

    @Override
    public void rebind(Object servant, String name) {
    	logger.write("rebinding Object with " + name);
    	addReference(name, new Dispatcher(servant));
    	try {
			nsc.sendRebind(name);
		} catch (IOException e) {
			throw new IllegalStateException(e);
		}
    }

    /* returns an ObjRef, which can be narrowCasted */
    @Override
    public Object resolve(String name) {
    	logger.write("resolving " + name);
    	try {
			return nsc.sendResolve(name);
		} catch (IOException e) {
			e.printStackTrace();
		}
        return null;
    }

    public void addReference(String refName, Dispatcher obj) {
        referenceMap.put(refName, obj);
    }

    public Dispatcher getReference(String refName) {
        return referenceMap.get(refName);
    }
}
