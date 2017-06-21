import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDateTime;

/**
 * This class is able to handle multiple threads, but it certainly won't work using different instances of this class
 * with the same fileName. (example: client.log, server.log, wrapper.log)
 */
public class Log {
    private final String fileName;
    private final boolean debug;

    public Log(boolean debug, String fileName) {
        this.debug = debug;
        this.fileName = fileName;
        new File(fileName).delete();
    }

    public synchronized void write(String text) {
        if (!debug) return;
        try (FileWriter fileWriter = new FileWriter(fileName, true)) {
            System.out.println(text);
            fileWriter.write(LocalDateTime.now() + ": " + text + "\n");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
