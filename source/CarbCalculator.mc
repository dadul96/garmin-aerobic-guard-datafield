class CarbCalculator {
    function calculate(elapsedSeconds, gramsPerHour) {
        if (elapsedSeconds == null || elapsedSeconds < 0 || gramsPerHour <= 0) {
            return null;
        }
        var blocks = (elapsedSeconds / 600).toNumber();
        return ((gramsPerHour * blocks / 6.0) + 0.5).toNumber();
    }
}
