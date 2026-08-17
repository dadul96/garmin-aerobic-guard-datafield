class DashboardLayout {
    var bannerHeight = 44;

    var powerY = 0;
    var powerHeight = 0;
    var hrY = 0;
    var hrHeight = 0;
    var cadenceY = 0;
    var cadenceHeight = 0;
    var contextY = 0;
    var contextHeight = 0;
    var footerY = 0;
    var footerHeight = 0;

    function configure(height, showPower, showHr, showCadence, showContext) {
        powerHeight = 0;
        hrHeight = 0;
        cadenceHeight = 0;
        contextHeight = 0;

        // Guidance cards receive twice the vertical weight of context and
        // footer cards. The footer consumes integer division's remainder so
        // the layout always reaches the bottom edge exactly.
        var weight = 1;
        if (showPower) { weight += 2; }
        if (showHr) { weight += 2; }
        if (showCadence) { weight += 2; }
        if (showContext) { weight += 1; }

        var unit = (height - bannerHeight) / weight;
        var y = bannerHeight;
        if (showPower) {
            powerY = y; powerHeight = unit * 2; y += powerHeight;
        }
        if (showHr) {
            hrY = y; hrHeight = unit * 2; y += hrHeight;
        }
        if (showCadence) {
            cadenceY = y; cadenceHeight = unit * 2; y += cadenceHeight;
        }
        if (showContext) {
            contextY = y; contextHeight = unit; y += contextHeight;
        }
        footerY = y;
        footerHeight = height - y;
    }
}
