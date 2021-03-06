package mware_lib;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;

/**
 * - mutable
 *
 * @param
 * @return
 */
public class ObjectBroker {
    private final NameServiceImpl nameService;
    private final Log logger;
    
    private static final String configFileName = "mware.config";
    
    //filled with default values - will be overriden by config file, if available
    private String logFileName = "mware_client.log";
    private int rmiPort = 15001;
    private String rmiInetAddress = "127.0.0.1";
    
    private ObjectBroker(String host, int port, boolean debug) {
        readConfig();
        logger = new Log(debug, logFileName);
        nameService = new NameServiceImpl(host, port, debug);
        MethodCallListener mcl = new MethodCallListener(rmiPort, nameService, logger);
        nameService.initialize(rmiPort, rmiInetAddress, logger);
        new Thread(mcl).start();
    }
    
    private void readConfig() {
    	File f = new File(configFileName);
    	try(BufferedReader br = new BufferedReader(new FileReader(f))) {
			logFileName = br.readLine();
			rmiPort = Integer.parseInt(br.readLine());
			rmiInetAddress = br.readLine();
		} catch (FileNotFoundException e) {
			System.out.println("File not found!");
		} catch (IOException e) {
			System.out.println("incomplete configfile");
		}
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
