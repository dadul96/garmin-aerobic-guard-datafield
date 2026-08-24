import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.WatchUi;

class AerobicGuardField extends WatchUi.DataField {
    var mSettings as SettingsModel;
    var mCarbs as CarbCalculator;
    var mRenderer as DashboardRenderer;
    var mPowerAverage as PowerMovingAverage;
    var mState as DisplayState;
    var mNormalizer as ActivityValueNormalizer;
    var mZoneInitializationPending;

    function initialize() {
        DataField.initialize();
        mSettings = new SettingsModel();
        mCarbs = new CarbCalculator();
        mRenderer = new DashboardRenderer();
        mPowerAverage = new PowerMovingAverage();
        mZoneInitializationPending = true;
        mState = new DisplayState();
        mNormalizer = new ActivityValueNormalizer();
        loadHrRange();
    }

    function onSettingsChanged() { mSettings.reload(); }

    function compute(info as Activity.Info) as Void {
        if (mZoneInitializationPending) {
            mZoneInitializationPending = false;
            new ZoneDefaultsInitializer().initializeOnce();
            mSettings.reload();
        }
        var power = mNormalizer.number(info.currentPower, false);
        var heartRate = mNormalizer.number(info.currentHeartRate, false);
        var cadence = mNormalizer.number(info.currentCadence, false);
        var speed = mNormalizer.number(info.currentSpeed, false);
        // Activity.Info elapsed values are milliseconds.
        var elapsedMs = mNormalizer.number(info.elapsedTime, false);
        var elapsed = elapsedMs == null ? null : (elapsedMs / 1000).toNumber();
        mState.power = mPowerAverage.add(power, mSettings.powerAverageSeconds);
        mState.heartRate = heartRate;
        mState.cadence = cadence;
        mState.averagePower = mNormalizer.number(info.averagePower, false);
        mState.averageHeartRate = mNormalizer.number(info.averageHeartRate, false);
        mState.averageCadence = mNormalizer.number(info.averageCadence, false);
        mState.speed = speed;
        mState.elapsed = elapsed;
        mState.carbs = mCarbs.calculate(elapsed, mSettings.carbRate);
    }

    function onUpdate(dc as Dc) as Void { mRenderer.draw(dc, mState, mSettings); }

    function onTimerStart() as Void { clearActivityState(); }
    function onTimerPause() as Void { clearActivityState(); }
    function onTimerResume() as Void { clearActivityState(); }
    function onTimerStop() as Void { clearActivityState(); }
    function onTimerReset() as Void { clearActivityState(); }

    private function clearActivityState() {
        mState.clearReadings();
        mPowerAverage.reset();
    }

    private function loadHrRange() {
        try {
            var zones = UserProfile.getHeartRateZones2(Activity.SPORT_CYCLING);
            if (zones != null && zones.size() == 6 && zones[0] != null && zones[5] != null && zones[0] > 0 && zones[5] > zones[0]) {
                mState.hrMin = zones[0]; mState.hrMax = zones[5];
            }
        } catch (error) {
            // Numeric HR and the configured ceiling remain useful without zone data.
        }
    }
}
