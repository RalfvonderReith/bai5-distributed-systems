import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class NameServer {
	
	private Map<String, ObjRef> referenceMap;
	private NameServerListener nsl;
	private String logFileName = "nameserver.log";
	private String configFileName = "nameserver.config";
	private boolean debug = true;
	private int port = 15000;
	private final Log logger;
	
	public NameServer() {
		readConfig();
		logger = new Log(debug, logFileName);
		referenceMap = new ConcurrentHashMap<>();
		nsl = new NameServerListener(port, this, logger);
		new Thread(nsl).start();
	}
	
	public void addReference(ObjRef ref) {
		referenceMap.put(ref.getRefName(), ref);
	}
	
	public ObjRef getReference(String refName) {
		return referenceMap.get(refName);
	}
	

    private void readConfig() {
    	File f = new File(configFileName);
    	try(BufferedReader br = new BufferedReader(new FileReader(f))) {
			logFileName = br.readLine();
			port = Integer.parseInt(br.readLine());
		} catch (FileNotFoundException e) {
			System.out.println("File not found!");
		} catch (IOException e) {
			System.out.println("incomplete configfile");
		}
    }
	
	public static void main(String[] args) {
		new NameServer();
	}
	
}
