package mware_lib;

import java.lang.reflect.InvocationTargetException;

public class Dispatcher {
    private final Object remoteObject;

    public Dispatcher(Object remoteObject) {
        this.remoteObject = remoteObject;
    }

    public Object call(RmiObject rmiObject) {
        try {
            return remoteObject
                    .getClass()
                    .getDeclaredMethod(rmiObject.methodName(), rmiObject.paramTypes())
                    .invoke(remoteObject, (Object[]) rmiObject.params());
        } catch (NoSuchMethodException | IllegalAccessException | InvocationTargetException e) {
            return e;
        }
    }
}
