import java.io.Serializable;
import java.util.Arrays;

public class RmiObject implements Serializable {
    /**
	 * 
	 */
	private static final long serialVersionUID = -81011920543959753L;
	private final String refName;
    private final String methodName;
    private final Serializable params[];
    private final Class<?> paramTypes[];

    public RmiObject(String refName, String methodName, Serializable params[], Class<?> paramTypes[]) {
        this.refName = refName;
        this.methodName = methodName;
        this.params = params;
        this.paramTypes = paramTypes;
    }

    public String refName() {
        return refName;
    }

    public String methodName() {
        return methodName;
    }

    public Serializable[] params() {
        return Arrays.copyOf(params, params.length);
    }

    public Class<?>[] paramTypes() {
        return Arrays.copyOf(paramTypes, paramTypes.length);
    }
}
