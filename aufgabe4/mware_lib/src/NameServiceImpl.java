package mware_lib;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.concurrent.ConcurrentHashMap;

public class NameServiceImpl extends NameService {

    private ConcurrentHashMap<String, Dispatcher> referenceMap;
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
            nsc = NameServiceConnection.connect(InetAddress.getByName(host), port, rmiAddress, rmiPort);
            System.out.println("Success!");
        } catch (UnknownHostException e) {
        	System.out.println("Failed:");
            e.printStackTrace();
        }
    }

    @Override
    public void rebind(Object servant, String name) {
    	System.out.println("rebinding Object with " + name);
    	addReference(name, new Dispatcher(servant));
    	try {
			nsc.sendRebind(name);
		} catch (IOException e) {
			e.printStackTrace();
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
