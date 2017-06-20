import mware_lib.Dispatcher;
import mware_lib.NameService;
import mware_lib.NameServiceConnection;

import java.io.IOException;
import java.net.InetAddress;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class NameServiceImpl extends NameService {

    private Map<String, Dispatcher> referenceMap = new ConcurrentHashMap<>();
    private NameServiceConnection nsc;
    private boolean debug = false;
    private String host;
    private int port;

    NameServiceImpl(String host, int port, boolean debug) {
    	this.port = port;
    	this.host = host;
        this.debug = debug;
    }
    
    public void initialize(int rmiPort, InetAddress rmiAddress) {
    	System.out.print("Starting NameService...");
        try {
            nsc = new NameServiceConnection(host, port, rmiAddress, rmiPort);
            System.out.println("Success!");
        } catch (IOException e) {
        	System.out.println("Failed:");
            e.printStackTrace();
        }
        System.out.println("initialized");
    }

    @Override
    public void rebind(Object servant, String name) {
    	System.out.println("rebinding Object with " + name);
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
    	System.out.println("resolving " + name);
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
