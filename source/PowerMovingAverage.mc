import Toybox.Lang;

// Fixed-capacity rolling average for the displayed power value. A missing
// current sample clears the history so stale power is never carried over.
class PowerMovingAverage {
    const MAX_WINDOW = 30;

    var mSamples as Array<Number> = new [MAX_WINDOW] as Array<Number>;
    var mWindow = 1;
    var mNext = 0;
    var mCount = 0;
    var mSum = 0;

    function add(value, window) {
        var boundedWindow = window < 1 ? 1 : (window > MAX_WINDOW ? MAX_WINDOW : window);
        if (boundedWindow != mWindow) {
            reset();
            mWindow = boundedWindow;
        }
        if (value == null) {
            reset();
            return null;
        }

        if (mCount == mWindow) {
            mSum -= mSamples[mNext];
        } else {
            mCount += 1;
        }
        mSamples[mNext] = value;
        mSum += value;
        mNext = (mNext + 1) % mWindow;
        return ((mSum.toFloat() / mCount) + 0.5).toNumber();
    }

    function reset() {
        mNext = 0;
        mCount = 0;
        mSum = 0;
    }
}
