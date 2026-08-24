class DashboardLayout {
    var powerY = 0;
    var powerHeight = 0;
    var hrY = 0;
    var hrHeight = 0;
    var cadenceY = 0;
    var cadenceHeight = 0;
    var footerY = 282;
    var footerHeight = 40;
    var isFullScreen = false;
    var scale = 100;

    function configure(width, height, showPower, showHr, showCadence) {
        isFullScreen = (width == 246 && height == 322)
            || (width == 282 && height == 470)
            || (width == 420 && height == 600)
            || (width == 480 && height == 800);
        if (height >= 800) { scale = 180; footerHeight = 78; }
        else if (height >= 600) { scale = 155; footerHeight = 64; }
        else if (height >= 470) { scale = 125; footerHeight = 54; }
        else { scale = 100; footerHeight = 40; }
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
