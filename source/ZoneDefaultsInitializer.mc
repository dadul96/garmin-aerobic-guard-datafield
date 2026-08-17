import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.UserProfile;

class ZoneDefaults {
    function derive(heartRateZones as Array<Number>?, powerZones as Array<Number>?, ftp) as Dictionary<Symbol, Number> {
        var defaults = { :hrCeiling => 0, :powerLow => 0, :powerHigh => 0 } as Dictionary<Symbol, Number>;
        if (validHeartRateThresholds(heartRateZones)) {
            defaults[:hrCeiling] = heartRateZones[2];
        }
        if (validPowerThresholds(powerZones)) {
            defaults[:powerLow] = powerZones[1] + 1;
            defaults[:powerHigh] = powerZones[2];
        } else if (ftp instanceof Number && ftp > 0) {
            defaults[:powerLow] = Math.ceil(ftp * 0.56).toNumber();
            defaults[:powerHigh] = Math.floor(ftp * 0.75).toNumber();
        }
        return defaults;
    }

    private function validHeartRateThresholds(zones as Array<Number>?) as Boolean {
        return zones != null && zones.size() >= 3
            && zones[0] instanceof Number && zones[1] instanceof Number && zones[2] instanceof Number
            && zones[0] > 0 && zones[1] >= zones[0] && zones[2] > zones[1];
    }

    private function validPowerThresholds(zones as Array<Number>?) as Boolean {
        return zones != null && zones.size() >= 3
            && zones[1] instanceof Number && zones[2] instanceof Number
            && zones[1] >= 0 && zones[2] > zones[1];
    }
}

class ZoneDefaultsInitializer {
    function initializeOnce() {
        var initialAttempted = Application.Properties.getValue("zoneDefaultsInitialized") == true;
        var ftpFallbackAttempted = Application.Properties.getValue("powerZoneFtpFallbackV5Initialized") == true;
        var needsPowerImport = numberProperty("powerLow") == 0
            && numberProperty("powerHigh") == 0;
        if (initialAttempted && ftpFallbackAttempted) { return; }

        var heartRateZones = null;
        var powerZones = null;
        var ftp = null;
        if (!initialAttempted) {
            try {
                if (UserProfile has :getHeartRateZones2) {
                    heartRateZones = UserProfile.getHeartRateZones2(Activity.SPORT_CYCLING);
                }
            } catch (error) {
                // A failed first lookup deliberately leaves the HR target unconfigured.
            }
        }
        if (needsPowerImport && !ftpFallbackAttempted) {
            try {
                if (UserProfile has :getPowerZones) {
                    powerZones = UserProfile.getPowerZones(Activity.SPORT_CYCLING);
                }
            } catch (error) {
                // FTP fallback below remains available when zone retrieval fails.
            }
            try {
                if (UserProfile has :getFunctionalThresholdPower) {
                    ftp = UserProfile.getFunctionalThresholdPower(Activity.SPORT_CYCLING);
                }
            } catch (error) {
                // A failed FTP lookup deliberately leaves power unconfigured.
            }
        }

        var defaults = new ZoneDefaults().derive(heartRateZones, powerZones, ftp) as Dictionary<Symbol, Number>;
        if (!initialAttempted) { applyHeartRate(defaults[:hrCeiling]); }
        applyPower(defaults[:powerLow], defaults[:powerHigh]);
        Application.Properties.setValue("zoneDefaultsInitialized", true);
        Application.Properties.setValue("powerZoneFtpFallbackV5Initialized", true);
    }

    private function applyHeartRate(ceiling) {
        var existing = numberProperty("hrCeiling");
        if (existing == 0 && ceiling > 0) {
            Application.Properties.setValue("hrCeiling", ceiling);
            Application.Properties.setValue("hrEnabled", true);
        }
    }

    private function applyPower(lower, upper) {
        var existingLower = numberProperty("powerLow");
        var existingUpper = numberProperty("powerHigh");
        if (existingLower == 0 && existingUpper == 0 && lower > 0 && upper > lower) {
            Application.Properties.setValue("powerLow", lower);
            Application.Properties.setValue("powerHigh", upper);
            Application.Properties.setValue("powerEnabled", true);
        }
    }

    private function numberProperty(key) {
        var value = Application.Properties.getValue(key);
        return value instanceof Number ? value : 0;
    }
}

class AdvisoryDefaults {
    function values() as Dictionary<Symbol, Number> {
        return { :cadenceLow => 80, :cadenceHigh => 95, :carbRate => 60 } as Dictionary<Symbol, Number>;
    }
}

class AdvisoryDefaultsInitializer {
    function initializeOnce() {
        if (Application.Properties.getValue("advisoryDefaultsInitialized") == true) { return; }
        var defaults = new AdvisoryDefaults().values() as Dictionary<Symbol, Number>;

        var cadenceLow = numberProperty("cadenceLow");
        var cadenceHigh = numberProperty("cadenceHigh");
        if (cadenceLow == 0 && cadenceHigh == 0) {
            Application.Properties.setValue("cadenceLow", defaults[:cadenceLow]);
            Application.Properties.setValue("cadenceHigh", defaults[:cadenceHigh]);
            Application.Properties.setValue("cadenceEnabled", true);
        }

        var carbRate = numberProperty("carbRate");
        if (carbRate == 0) {
            Application.Properties.setValue("carbRate", defaults[:carbRate]);
            Application.Properties.setValue("carbsEnabled", true);
        }

        Application.Properties.setValue("advisoryDefaultsInitialized", true);
    }

    private function numberProperty(key) {
        var value = Application.Properties.getValue(key);
        return value instanceof Number ? value : 0;
    }
}
