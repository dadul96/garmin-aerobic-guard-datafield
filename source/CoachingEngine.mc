class CoachingEngine {
    var mHrSeconds = 0;
    var mPowerHighSeconds = 0;
    var mPowerLowSeconds = 0;
    var mCadenceLowSeconds = 0;
    var mCadenceHighSeconds = 0;
    var mHrHigh = false;
    var mPowerHigh = false;
    var mPowerLow = false;
    var mCadenceLow = false;
    var mCadenceHigh = false;

    function update(power, heartRate, cadence, active, settings) {
        if (!active) {
            reset();
            return "PAUSED";
        }
        if (settings.hrEnabled && heartRate == null) { reset(); return "HR DATA --"; }
        if (settings.powerEnabled && power == null) { reset(); return "POWER DATA --"; }

        mHrSeconds = count(settings.hrEnabled && heartRate > settings.hrCeiling, mHrSeconds);
        mPowerHighSeconds = count(settings.powerEnabled && power > settings.powerHigh, mPowerHighSeconds);
        mPowerLowSeconds = count(settings.powerEnabled && power < settings.powerLow, mPowerLowSeconds);

        // Cadence coaching is suppressed while coasting (zero cadence or negligible power).
        var pedaling = cadence != null && cadence > 0 && (power == null || power > 10);
        mCadenceLowSeconds = count(settings.cadenceEnabled && pedaling && cadence < settings.cadenceLow, mCadenceLowSeconds);
        mCadenceHighSeconds = count(settings.cadenceEnabled && pedaling && cadence > settings.cadenceHigh, mCadenceHighSeconds);

        mHrHigh = reached(mHrSeconds, settings.hrDelay);
        mPowerHigh = reached(mPowerHighSeconds, settings.powerDelay);
        mPowerLow = reached(mPowerLowSeconds, settings.powerDelay);
        mCadenceLow = reached(mCadenceLowSeconds, settings.cadenceDelay);
        mCadenceHigh = reached(mCadenceHighSeconds, settings.cadenceDelay);

        if (mHrHigh) { return "EASE - HR HIGH"; }
        if (mPowerHigh) { return "EASE POWER"; }

        // Within 5 bpm of the ceiling, HR vetoes advice to add power.
        var hrVeto = settings.hrEnabled && heartRate != null && heartRate >= settings.hrCeiling - 5;
        if (!hrVeto && mPowerLow) { return "LIFT POWER"; }
        if (mCadenceLow) { return "SPIN FASTER"; }
        if (mCadenceHigh) { return "LOWER CADENCE"; }
        return "STEADY";
    }

    function isHrHigh() { return mHrHigh; }
    function isPowerHigh() { return mPowerHigh; }
    function isPowerLow() { return mPowerLow; }
    function isCadenceLow() { return mCadenceLow; }
    function isCadenceHigh() { return mCadenceHigh; }

    private function count(condition, previous) { return condition ? previous + 1 : 0; }
    private function reached(seconds, delay) { return seconds > 0 && seconds >= delay; }
    private function reset() {
        mHrSeconds = 0; mPowerHighSeconds = 0; mPowerLowSeconds = 0;
        mCadenceLowSeconds = 0; mCadenceHighSeconds = 0;
        mHrHigh = false; mPowerHigh = false; mPowerLow = false;
        mCadenceLow = false; mCadenceHigh = false;
    }
}
