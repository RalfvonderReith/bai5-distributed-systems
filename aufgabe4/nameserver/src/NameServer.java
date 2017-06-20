package nameserver;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import mware_lib.ObjRef;

public class NameServer {
	
	private Map<String, ObjRef> referenceMap;
	private NameServerListener nsl;
	
	public NameServer(int port) {
		referenceMap = new ConcurrentHashMap<>();
		nsl = new NameServerListener(port, this);
		new Thread(nsl).start();
	}
	
	public void addReference(ObjRef ref) {
		referenceMap.put(ref.getRefName(), ref);
	}
	
	public ObjRef getReference(String refName) {
		return referenceMap.get(refName);
	}
	
	public static void main(String[] args) {
		int port = 15000;
		System.out.println("starting NameServer on port " + port);
		new NameServer(port);
	}
	
}
