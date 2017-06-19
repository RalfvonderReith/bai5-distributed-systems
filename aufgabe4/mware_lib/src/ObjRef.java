package mware_lib;

import java.io.Serializable;
import java.net.InetAddress;

public class ObjRef implements Serializable {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1401776112847873409L;
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
