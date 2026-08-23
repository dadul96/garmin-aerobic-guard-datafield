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
    var mState as Dictionary;
    var mZoneInitializationPending;

    function initialize() {
        DataField.initialize();
        mSettings = new SettingsModel();
        mCarbs = new CarbCalculator();
        mRenderer = new DashboardRenderer();
        mPowerAverage = new PowerMovingAverage();
        mZoneInitializationPending = true;
        mState = { :power => null, :heartRate => null, :cadence => null, :speed => null,
            :averagePower => null, :averageHeartRate => null, :averageCadence => null,
            :elapsed => null, :carbs => null, :hrMin => null, :hrMax => null };
        loadHrRange();
    }

    function onSettingsChanged() { mSettings.reload(); }

    function compute(info as Activity.Info) as Void {
        if (mZoneInitializationPending) {
            mZoneInitializationPending = false;
            new ZoneDefaultsInitializer().initializeOnce();
            mSettings.reload();
        }
        var power = info.currentPower;
        var heartRate = info.currentHeartRate;
        var cadence = info.currentCadence;
        var speed = info.currentSpeed;
        // Activity.Info elapsed values are milliseconds.
        var elapsed = info.elapsedTime == null ? null : (info.elapsedTime / 1000).toNumber();
        mState[:power] = mPowerAverage.add(power, mSettings.powerAverageSeconds);
        mState[:heartRate] = heartRate;
        mState[:cadence] = cadence;
        mState[:averagePower] = info.averagePower;
        mState[:averageHeartRate] = info.averageHeartRate;
        mState[:averageCadence] = info.averageCadence;
        mState[:speed] = speed;
        mState[:elapsed] = elapsed;
        mState[:carbs] = mCarbs.calculate(elapsed, mSettings.carbRate);
    }

    function onUpdate(dc as Dc) as Void { mRenderer.draw(dc, mState, mSettings); }

    private function loadHrRange() {
        try {
            var zones = UserProfile.getHeartRateZones2(Activity.SPORT_CYCLING);
            if (zones != null && zones.size() == 6 && zones[0] != null && zones[5] != null && zones[0] > 0 && zones[5] > zones[0]) {
                mState[:hrMin] = zones[0]; mState[:hrMax] = zones[5];
            }
        } catch (error) {
            // Numeric HR and the configured ceiling remain useful without zone data.
        }
    }
}
