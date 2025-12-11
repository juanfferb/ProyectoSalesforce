public with sharing class FantasyValueService {

    private static final Decimal DRIVER_MIN = 5000000;   // 5M
    private static final Decimal DRIVER_MAX = 25000000;  // 25M
    private static final Decimal CONSTRUCTOR_MIN = 10000000;  // 10M
    private static final Decimal CONSTRUCTOR_MAX = 35000000;  // 35M

    // Precio aleatorio para pilotos
    public static Decimal getRandomDriverPrice() {
        return getRandomMillions(DRIVER_MIN, DRIVER_MAX);
    }

    // Precio aleatorio para escuderías
    public static Decimal getRandomConstructorPrice() {
        return getRandomMillions(CONSTRUCTOR_MIN, CONSTRUCTOR_MAX);
    }

    // Lógica común: número aleatorio en el rango, redondeado al millón más cercano
    private static Decimal getRandomMillions(Decimal minValue, Decimal maxValue) {
        Double r = Math.random(); // 0.0 <= r < 1.0

        Decimal raw = minValue + (maxValue - minValue) * r;

        Double inMillions = (Double)(raw / 1000000);
        Long roundedMillions = Math.round(inMillions);
        return Decimal.valueOf(roundedMillions) * 1000000;
    }
}