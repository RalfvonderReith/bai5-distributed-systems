package mware_lib;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.concurrent.ConcurrentHashMap;

public class NameServiceImpl extends NameService {

    private ConcurrentHashMap<String, ObjRef> referenceMap;
    private NameServiceConnection nsc;
    private boolean debug = false;

    NameServiceImpl(String host, int port, boolean debug) {
        try {
            nsc = NameServiceConnection.connect(InetAddress.getByName(host), port);
        } catch (UnknownHostException e) {
            e.printStackTrace();
        }
        this.debug = debug;
    }

    @Override
    public void rebind(Object servant, String name) {

    }

    @Override
    public Object resolve(String name) {
        return null;
    }

    public void addReference(ObjRef ref) {
        referenceMap.put(ref.getRefName(), ref);
    }

    public ObjRef getReference(String refName) {
        return referenceMap.get(refName);
    }
}
