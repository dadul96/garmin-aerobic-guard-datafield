import Toybox.Lang;

class ActivityValueNormalizer {
    function number(value, allowNegative) {
        if (!(value instanceof Number) && !(value instanceof Long)
                && !(value instanceof Float) && !(value instanceof Double)) {
            return null;
        }
        var result = value.toFloat();
        // Both NaN and infinity produce NaN when subtracted from themselves.
        // This rejects non-finite input without imposing a finite ride-length
        // cap or relying on optional math helpers.
        var finiteCheck = result - result;
        if (result != result || finiteCheck != finiteCheck) {
            return null;
        }
        if (!allowNegative && result < 0) { return null; }
        return value;
    }
}
