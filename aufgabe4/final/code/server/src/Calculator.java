public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }

    public double div(int a, int b) {
        if (a == 0) throw new IllegalArgumentException("Division by 0 is not allowed!");
        return (double) a / (double) b;
    }

    public String asString(int a) {
        return String.valueOf(a);
    }
}
