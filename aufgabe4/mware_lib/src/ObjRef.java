package mware_lib;

import java.net.InetAddress;

public class ObjRef {
	private final String refName;
	private final int port;
	private final InetAddress ip;
	
	public ObjRef(String refName, int port, InetAddress ip) {
		this.refName = refName;
		this.port = port;
		this.ip = ip;
	}
	
	public String getRefName() { 
		return refName; 
	}
	
	public int getPort() {
		return port;
	}
	
	public InetAddress getIp() {
		return ip;
	}
	
}
