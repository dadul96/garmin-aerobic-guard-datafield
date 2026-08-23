import Toybox.Application;

class SettingsModel {
    var powerEnabled;
    var powerLow;
    var powerHigh;
    var powerDelay;
    var powerAverageSeconds;
    var hrEnabled;
    var hrCeiling;
    var hrDelay;
    var cadenceEnabled;
    var cadenceLow;
    var cadenceHigh;
    var cadenceDelay;
    var carbsEnabled;
    var carbRate;
    var driftEnabled;
    var driftThreshold;

    function initialize() {
        reload();
    }

    function reload() {
        powerEnabled = boolProperty("powerEnabled") && validRange("powerLow", "powerHigh");
        powerLow = numberProperty("powerLow", 0);
        powerHigh = numberProperty("powerHigh", 0);
        powerDelay = boundedProperty("powerDelay", 5, 0, 120);
        powerAverageSeconds = boundedProperty("powerAverageSeconds", 1, 1, 30);
        hrCeiling = numberProperty("hrCeiling", 0);
        hrEnabled = boolProperty("hrEnabled") && hrCeiling > 0;
        hrDelay = boundedProperty("hrDelay", 20, 0, 120);
        cadenceEnabled = boolProperty("cadenceEnabled") && validRange("cadenceLow", "cadenceHigh");
        cadenceLow = numberProperty("cadenceLow", 0);
        cadenceHigh = numberProperty("cadenceHigh", 0);
        cadenceDelay = boundedProperty("cadenceDelay", 10, 0, 120);
        carbRate = numberProperty("carbRate", 0);
        carbsEnabled = boolProperty("carbsEnabled") && carbRate > 0;
        driftEnabled = boolProperty("driftEnabled");
        driftThreshold = boundedProperty("driftThreshold", 5, 0, 25);
    }

    private function boolProperty(key) {
        return Application.Properties.getValue(key) == true;
    }

    private function numberProperty(key, fallback) {
        var value = Application.Properties.getValue(key);
        return value instanceof Number ? value : fallback;
    }

    private function boundedProperty(key, fallback, minimum, maximum) {
        var value = numberProperty(key, fallback);
        return value < minimum ? minimum : (value > maximum ? maximum : value);
    }

    private function validRange(lowKey, highKey) {
        var low = numberProperty(lowKey, 0);
        var high = numberProperty(highKey, 0);
        return isValidTargetRange(low, high);
    }
}
