import Toybox.Lang;

class DriftCalculator {
    const WARMUP_SECONDS = 900;
    const BASELINE_END_SECONDS = 1800;
    const READY_SECONDS = 2400;
    const MIN_BASELINE_SAMPLES = 720;
    const MIN_RECENT_SAMPLES = 480;

    var mBaselinePower = 0.0;
    var mBaselineHr = 0.0;
    var mBaselineCount = 0;
    var mPowerBuckets as Array<Float> = new [10] as Array<Float>;
    var mHrBuckets as Array<Float> = new [10] as Array<Float>;
    var mCountBuckets as Array<Number> = new [10] as Array<Number>;
    var mMinuteIds as Array<Number> = new [10] as Array<Number>;

    function initialize() {
        for (var i = 0; i < 10; i += 1) { clearBucket(i, -1); }
    }

    function addSample(elapsedSeconds, power, heartRate, active) {
        if (!active || elapsedSeconds == null || power == null || heartRate == null || power <= 0 || heartRate <= 0) {
            return;
        }
        if (elapsedSeconds >= WARMUP_SECONDS && elapsedSeconds < BASELINE_END_SECONDS) {
            mBaselinePower += power;
            mBaselineHr += heartRate;
            mBaselineCount += 1;
        }
        if (elapsedSeconds >= BASELINE_END_SECONDS) {
            var minute = (elapsedSeconds / 60).toNumber();
            var slot = minute % 10;
            if (mMinuteIds[slot] != minute) { clearBucket(slot, minute); }
            mPowerBuckets[slot] += power;
            mHrBuckets[slot] += heartRate;
            mCountBuckets[slot] += 1;
        }
    }

    function value(elapsedSeconds) {
        if (elapsedSeconds == null || elapsedSeconds < READY_SECONDS || mBaselineCount < MIN_BASELINE_SAMPLES) { return null; }
        var power = 0.0; var hr = 0.0; var count = 0;
        var currentMinute = (elapsedSeconds / 60).toNumber();
        for (var i = 0; i < 10; i += 1) {
            if (mMinuteIds[i] >= currentMinute - 9 && mMinuteIds[i] <= currentMinute) {
                power += mPowerBuckets[i]; hr += mHrBuckets[i]; count += mCountBuckets[i];
            }
        }
        if (count < MIN_RECENT_SAMPLES || power <= 0 || hr <= 0) { return null; }
        var baselineEfficiency = mBaselinePower / mBaselineHr;
        var recentEfficiency = power / hr;
        return (1.0 - recentEfficiency / baselineEfficiency) * 100.0;
    }

    private function clearBucket(index, minute) {
        mPowerBuckets[index] = 0.0; mHrBuckets[index] = 0.0;
        mCountBuckets[index] = 0; mMinuteIds[index] = minute;
    }
}
