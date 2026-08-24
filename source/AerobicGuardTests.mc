import Toybox.Lang;
import Toybox.Test;

(:test)
function testPowerMovingAverage(logger as Test.Logger) as Boolean {
    var average = new PowerMovingAverage();
    if (average.add(100, 3) != 100
            || average.add(200, 3) != 150
            || average.add(300, 3) != 200
            || average.add(400, 3) != 300) {
        logger.error("Power rolling average is incorrect");
        return false;
    }
    if (average.add(null, 3) != null || average.add(500, 3) != 500) {
        logger.error("Missing power did not clear the rolling average");
        return false;
    }
    return average.add(501, 1) == 501;
}

(:test)
function testCarbohydrateBlocks(logger as Test.Logger) as Boolean {
    var calculator = new CarbCalculator();
    return calculator.calculate(599, 60) == 0
        && calculator.calculate(600, 60) == 10
        && calculator.calculate(1200, 80) == 27;
}

(:test)
function testNumericInputEditing(logger as Test.Logger) as Boolean {
    var model = new NumericInputModel(1, 1000, 170);
    model.appendDigit(1);
    model.appendDigit(8);
    model.appendDigit(0);
    if (!model.text().equals("180") || model.value() != 180) {
        logger.error("First digit did not replace the existing value");
        return false;
    }
    model.appendDigit(9);
    model.appendDigit(9);
    if (!model.text().equals("1809")) {
        logger.error("Maximum-derived input length failed");
        return false;
    }
    model.backspace();
    return model.text().equals("180");
}

(:test)
function testNumericInputValidation(logger as Test.Logger) as Boolean {
    var minimum = new NumericInputModel(10, 20, 0);
    if (minimum.value() != null) { return false; }
    minimum.appendDigit(9);
    if (minimum.value() != null) { return false; }
    minimum.backspace(); minimum.appendDigit(1); minimum.appendDigit(0);
    if (minimum.value() != 10) { return false; }

    var maximum = new NumericInputModel(10, 20, 0);
    maximum.appendDigit(2); maximum.appendDigit(0);
    if (maximum.value() != 20) { return false; }
    maximum.appendDigit(1);
    return maximum.value() == null;
}

(:test)
function testTargetRangeValidation(logger as Test.Logger) as Boolean {
    return isValidTargetRange(170, 200)
        && !isValidTargetRange(200, 200)
        && !isValidTargetRange(201, 200)
        && !isValidTargetRange(0, 200)
        && acceptsTargetBound(170, 200, true)
        && !acceptsTargetBound(200, 200, true)
        && acceptsTargetBound(200, 170, false)
        && !acceptsTargetBound(170, 170, false)
        && acceptsTargetBound(170, 0, true)
        && acceptsTargetBound(200, 0, false);
}

(:test)
function testNumericKeypadHitMapping(logger as Test.Logger) as Boolean {
    var model = new NumericInputModel(0, 1000, 0);
    if (model.actionAt(123, 50, 246, 322, 96) != null) { return false; }
    if (model.actionAt(-1, 124, 246, 322, 96) != null) { return false; }
    if (model.actionAt(41, 124, 246, 322, 96) != 0) { return false; }
    if (model.actionAt(205, 124, 246, 322, 96) != 2) { return false; }
    if (model.actionAt(41, 294, 246, 322, 96) != 9) { return false; }
    if (model.actionAt(123, 294, 246, 322, 96) != 10) { return false; }
    return model.actionAt(205, 294, 246, 322, 96) == 11;
}

(:test)
function testNumericKeypadButtonFocus(logger as Test.Logger) as Boolean {
    var model = new NumericInputModel(0, 1000, 170);
    if (model.selectedAction() != 11) { return false; }
    model.moveSelection(1);
    if (model.selectedAction() != 0) { return false; }
    model.moveSelection(-1);
    model.moveSelection(-1);
    return model.selectedAction() == 10;
}

(:test)
function testZoneDefaults(logger as Test.Logger) as Boolean {
    var defaults = new ZoneDefaults().derive([90, 119, 139, 159, 179, 200],
        [0, 149, 199, 249, 299, 349, 399, 2000], 200);
    return defaults[:hrCeiling] == 139
        && defaults[:powerLow] == 150
        && defaults[:powerHigh] == 199;
}

(:test)
function testInvalidZoneDefaultsStayZero(logger as Test.Logger) as Boolean {
    var defaults = new ZoneDefaults().derive(null, [1, 149], null);
    return defaults[:hrCeiling] == 0
        && defaults[:powerLow] == 0
        && defaults[:powerHigh] == 0;
}

(:test)
function testPowerDefaultsIgnoreUnusedFirstThreshold(logger as Test.Logger) as Boolean {
    var defaults = new ZoneDefaults().derive(null, [-1, 149, 199], 200);
    return defaults[:powerLow] == 150 && defaults[:powerHigh] == 199;
}

(:test)
function testPowerDefaultsFallBackToFtp(logger as Test.Logger) as Boolean {
    var defaults = new ZoneDefaults().derive(null, null, 200);
    return defaults[:powerLow] == 112 && defaults[:powerHigh] == 150;
}

(:test)
function testAdvisoryDefaults(logger as Test.Logger) as Boolean {
    var defaults = new AdvisoryDefaults().values();
    return defaults[:cadenceLow] == 80
        && defaults[:cadenceHigh] == 95
        && defaults[:carbRate] == 60;
}

(:test)
function testFixedLiveBarDashboardLayout(logger as Test.Logger) as Boolean {
    var layout = new DashboardLayout();
    layout.configure(246, 322, true, true, true);
    if (layout.powerY != 0 || layout.powerHeight != 94
            || layout.hrY != 94 || layout.hrHeight != 94
            || layout.cadenceY != 188 || layout.cadenceHeight != 94
            || layout.footerY != 282 || layout.footerHeight != 40) {
        return false;
    }
    layout.configure(246, 322, true, false, true);
    if (layout.powerY != 0 || layout.powerHeight != 141
            || layout.hrHeight != 0 || layout.cadenceY != 141
            || layout.cadenceHeight != 141) {
        return false;
    }
    layout.configure(246, 322, false, true, false);
    return layout.powerHeight == 0 && layout.hrY == 0
        && layout.hrHeight == 282 && layout.cadenceHeight == 0;
}

(:test)
function testResponsiveLayoutTiers(logger as Test.Logger) as Boolean {
    var layout = new DashboardLayout();
    var sizes = [[246, 322], [282, 470], [420, 600], [480, 800]];
    for (var index = 0; index < sizes.size(); index += 1) {
        layout.configure(sizes[index][0], sizes[index][1], true, true, true);
        if (!layout.isFullScreen || layout.powerHeight <= 0
                || layout.powerHeight != layout.hrHeight
                || layout.hrHeight != layout.cadenceHeight
                || layout.footerY + layout.footerHeight != sizes[index][1]) {
            return false;
        }
    }
    layout.configure(200, 200, true, true, true);
    return !layout.isFullScreen;
}

(:test)
function testActivityValueNormalizer(logger as Test.Logger) as Boolean {
    var normalizer = new ActivityValueNormalizer();
    return normalizer.number(0, false) == 0
        && normalizer.number(-1, false) == null
        && normalizer.number("12", false) == null
        && normalizer.number(12.5, false) == 12.5;
}
