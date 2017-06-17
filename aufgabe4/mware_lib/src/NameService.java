package mware_lib;

public abstract class NameService {
    public abstract void rebind(Object servant, String name);
    public abstract Object resolve(String name);
}
