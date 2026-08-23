class DashboardLayout {
    var powerY = 0;
    var powerHeight = 0;
    var hrY = 0;
    var hrHeight = 0;
    var cadenceY = 0;
    var cadenceHeight = 0;
    var footerY = 282;
    var footerHeight = 40;

    function configure(height, showPower, showHr, showCadence) {
        powerHeight = 0;
        hrHeight = 0;
        cadenceHeight = 0;
        footerY = height - footerHeight;

        var visibleCount = 0;
        if (showPower) { visibleCount += 1; }
        if (showHr) { visibleCount += 1; }
        if (showCadence) { visibleCount += 1; }
        if (visibleCount == 0) { return; }

        var remainingHeight = footerY;
        var remainingCount = visibleCount;
        var y = 0;
        if (showPower) {
            powerY = y;
            powerHeight = remainingHeight / remainingCount;
            y += powerHeight;
            remainingHeight -= powerHeight;
            remainingCount -= 1;
        }
        if (showHr) {
            hrY = y;
            hrHeight = remainingHeight / remainingCount;
            y += hrHeight;
            remainingHeight -= hrHeight;
            remainingCount -= 1;
        }
        if (showCadence) {
            cadenceY = y;
            cadenceHeight = remainingHeight;
        }
    }
}
