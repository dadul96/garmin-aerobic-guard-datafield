import Toybox.Lang;
import Toybox.Test;

(:test)
class TestSettings {
    var powerEnabled = true;
    var powerLow = 170;
    var powerHigh = 200;
    var powerDelay = 5;
    var hrEnabled = true;
    var hrCeiling = 142;
    var hrDelay = 20;
    var cadenceEnabled = true;
    var cadenceLow = 82;
    var cadenceHigh = 95;
    var cadenceDelay = 10;
}

(:test)
function testCoachingPersistence(logger as Test.Logger) as Boolean {
    var engine = new CoachingEngine();
    var settings = new TestSettings();
    for (var i = 0; i < 4; i += 1) {
        var early = engine.update(220, 130, 90, true, settings);
        if (!early.equals("STEADY")) {
            logger.error("Expected STEADY before delay, got " + early);
            return false;
        }
    }
    var result = engine.update(220, 130, 90, true, settings);
    if (!result.equals("EASE POWER")) {
        logger.error("Expected EASE POWER at delay, got " + result);
        return false;
    }
    return true;
}

(:test)
function testCoachingPriority(logger as Test.Logger) as Boolean {
    var engine = new CoachingEngine();
    var settings = new TestSettings();
    var result = "";
    for (var i = 0; i < 20; i += 1) {
        result = engine.update(220, 150, 70, true, settings);
    }
    if (!result.equals("EASE - HR HIGH")) {
        logger.error("Expected HR priority, got " + result);
        return false;
    }
    return true;
}

(:test)
function testSimultaneousPersistedWarnings(logger as Test.Logger) as Boolean {
    var engine = new CoachingEngine();
    var settings = new TestSettings();
    var result = "";
    for (var i = 0; i < 20; i += 1) {
        result = engine.update(220, 150, 90, true, settings);
    }
    if (!result.equals("EASE - HR HIGH") || !engine.isHrHigh()
            || !engine.isPowerHigh()) {
        logger.error("HR priority hid a simultaneous high-power warning");
        return false;
    }

    engine = new CoachingEngine();
    for (var j = 0; j < 20; j += 1) {
        result = engine.update(150, 150, 70, true, settings);
    }
    return engine.isHrHigh() && engine.isPowerLow() && engine.isCadenceLow();
}

(:test)
function testHeartRateVeto(logger as Test.Logger) as Boolean {
    var engine = new CoachingEngine();
    var settings = new TestSettings();
    var result = "";
    for (var i = 0; i < 8; i += 1) {
        result = engine.update(150, 139, 90, true, settings);
    }
    if (!result.equals("STEADY")) {
        logger.error("Expected HR veto to remain STEADY, got " + result);
        return false;
    }
    return true;
}

(:test)
function testDriftReadinessAndValue(logger as Test.Logger) as Boolean {
    var drift = new DriftCalculator();
    for (var second = 900; second < 1800; second += 1) {
        drift.addSample(second, 180, 135, true);
    }
    for (var second = 1800; second < 2400; second += 1) {
        drift.addSample(second, 171, 135, true);
    }
    if (drift.value(2399) != null) { return false; }
    var value = drift.value(2400);
    return value != null && value > 4.99 && value < 5.01;
}

(:test)
function testDriftWarningThreshold(logger as Test.Logger) as Boolean {
    return !driftIsHigh(null, 5)
        && !driftIsHigh(4.9, 5)
        && driftIsHigh(5.0, 5)
        && driftIsHigh(6.0, 5);
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
function testAdaptiveDashboardLayout(logger as Test.Logger) as Boolean {
    var layout = new DashboardLayout();
    layout.configure(322, true, true, true, true);
    if (layout.powerY != 44 || layout.powerHeight != 68
            || layout.hrY != 112 || layout.hrHeight != 68
            || layout.cadenceY != 180 || layout.cadenceHeight != 68
            || layout.contextY != 248 || layout.contextHeight != 34
            || layout.footerY != 282 || layout.footerHeight != 40) {
        logger.error("All-enabled dashboard geometry is incorrect");
        return false;
    }

    layout.configure(322, true, false, false, false);
    if (layout.powerHeight != 184 || layout.hrHeight != 0
            || layout.cadenceHeight != 0 || layout.contextHeight != 0
            || layout.footerY != 228 || layout.footerHeight != 94) {
        logger.error("Reduced dashboard did not reallocate hidden-card space");
        return false;
    }

    layout.configure(322, false, false, false, true);
    return layout.contextY == 44 && layout.contextHeight == 139
        && layout.footerY == 183 && layout.footerHeight == 139;
}
