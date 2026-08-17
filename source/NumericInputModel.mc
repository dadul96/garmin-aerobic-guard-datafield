class NumericInputModel {
    var mMinimum;
    var mMaximum;
    var mText;
    var mFresh = true;
    var mSelectedAction = 11;

    function initialize(minimum, maximum, current) {
        mMinimum = minimum;
        mMaximum = maximum;
        mText = current > 0 ? current.format("%d") : "";
    }

    function appendDigit(digit) {
        if (mFresh) {
            mText = "";
            mFresh = false;
        }
        if (mText.length() < mMaximum.format("%d").length()) {
            mText += digit.format("%d");
        }
    }

    function backspace() {
        mFresh = false;
        if (mText.length() > 0) {
            mText = mText.substring(0, mText.length() - 1);
        }
    }

    function text() { return mText; }
    function selectedAction() { return mSelectedAction; }

    function moveSelection(delta) {
        mSelectedAction = (mSelectedAction + delta + 12) % 12;
    }

    function value() {
        if (mText.length() == 0) { return null; }
        var parsed = mText.toNumber();
        return parsed >= mMinimum && parsed <= mMaximum ? parsed : null;
    }

    // Returns 0-11 for the keypad cells, or null outside the keypad.
    function actionAt(x, y, width, height, gridTop) {
        if (width <= 0 || height <= gridTop || x < 0 || x >= width
                || y < gridTop || y >= height) { return null; }
        var column = (x * 3 / width).toNumber();
        var row = ((y - gridTop) * 4 / (height - gridTop)).toNumber();
        return row * 3 + column;
    }
}
