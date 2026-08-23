import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.WatchUi;

class AerobicGuardField extends WatchUi.DataField {
    var mSettings as SettingsModel;
    var mCoach as CoachingEngine;
    var mDrift as DriftCalculator;
    var mCarbs as CarbCalculator;
    var mRenderer as DashboardRenderer;
    var mPowerAverage as PowerMovingAverage;
    var mState as Dictionary;
    var mZoneInitializationPending;

    function initialize() {
        DataField.initialize();
        mSettings = new SettingsModel();
        mCoach = new CoachingEngine();
        mDrift = new DriftCalculator();
        mCarbs = new CarbCalculator();
        mRenderer = new DashboardRenderer();
        mPowerAverage = new PowerMovingAverage();
        mZoneInitializationPending = true;
        mState = { :power => null, :heartRate => null, :cadence => null, :speed => null,
            :elapsed => null, :coach => "WAITING FOR DATA", :drift => null, :carbs => null,
            :hrMin => null, :hrMax => null, :hrHigh => false, :powerHigh => false,
            :powerLow => false, :cadenceLow => false, :cadenceHigh => false };
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
        var active = info.timerState == Activity.TIMER_STATE_ON;

        // Filtering is presentation-only. Coaching and drift retain raw power.
        mState[:power] = mPowerAverage.add(power, mSettings.powerAverageSeconds);
        mState[:heartRate] = heartRate;
        mState[:cadence] = cadence;
        mState[:speed] = speed;
        mState[:elapsed] = elapsed;
        mState[:coach] = mCoach.update(power, heartRate, cadence, active, mSettings);
        mState[:hrHigh] = mCoach.isHrHigh();
        mState[:powerHigh] = mCoach.isPowerHigh();
        mState[:powerLow] = mCoach.isPowerLow();
        mState[:cadenceLow] = mCoach.isCadenceLow();
        mState[:cadenceHigh] = mCoach.isCadenceHigh();
        mDrift.addSample(elapsed, power, heartRate, active);
        mState[:drift] = mDrift.value(elapsed);
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
