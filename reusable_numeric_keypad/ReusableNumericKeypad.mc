import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Host integration boundary. Integer keypads return a Number; decimal keypads
// return a Float with exactly one supported fractional digit.
class ReusableNumericKeypadListener {
    function onNumericKeypadAccepted(value as Numeric) as Void {}
    function onNumericKeypadCancelled() as Void {}
}

// Non-negative inclusive integer keypad with a 3x4 layout.
class ReusableIntegerKeypad extends ReusableNumericKeypadBase {
    function initialize(
        title as String,
        minimum as Number,
        maximum as Number,
        initialValue as Number?
    ) {
        ReusableNumericKeypadBase.initialize(
            title, minimum, maximum, 0, initialValue);
    }
}

// Non-negative keypad with fixed 0.1 resolution. It uses a 3x5 layout so
// decimal, backspace, zero, and a full-width OK control all remain available.
class ReusableDecimalKeypad extends ReusableNumericKeypadBase {
    function initialize(
        title as String,
        minimum as Numeric,
        maximum as Numeric,
        initialValue as Numeric?
    ) {
        ReusableNumericKeypadBase.initialize(
            title,
            scaleTenths(minimum),
            scaleTenths(maximum),
            1,
            initialValue == null ? null : scaleTenths(initialValue as Numeric));
    }

    private function scaleTenths(value as Numeric) as Number {
        return (value.toFloat() * 10.0f + 0.5f).toNumber();
    }
}

// Shared input model, responsive renderer, and hit testing. Applications
// normally construct one of the two concrete keypad classes above.
class ReusableNumericKeypadBase extends WatchUi.View {
    const ACTION_BACKSPACE = 9;
    const ACTION_ZERO = 10;
    const ACTION_DECIMAL = 11;
    const ACTION_INTEGER_OK = 11;
    const ACTION_DECIMAL_OK = 12;

    private var mTitle as String;
    private var mMinimumScaled as Number;
    private var mMaximumScaled as Number;
    private var mDecimalPlaces as Number;
    private var mScale as Number;
    private var mText as String;
    private var mError as Boolean = false;
    private var mFresh as Boolean = true;
    private var mSelectedAction as Number;
    private var mWidth as Number = 1;
    private var mHeight as Number = 1;
    private var mGridTop as Number = 1;

    function initialize(
        title as String,
        minimumScaled as Number,
        maximumScaled as Number,
        decimalPlaces as Number,
        initialScaled as Number?
    ) {
        View.initialize();
        mTitle = title;
        mMinimumScaled = minimumScaled;
        mMaximumScaled = maximumScaled;
        mDecimalPlaces = decimalPlaces;
        mScale = decimalPlaces == 0 ? 1 : 10;
        mText = initialScaled == null ? "" :
            formatScaled(initialScaled as Number);
        // Enter can accept an unchanged initial value on button-only devices.
        mSelectedAction = getOkAction();
    }

    function appendDigit(digit as Number) as Void {
        if (mFresh) {
            mText = "";
            mFresh = false;
        }
        var decimalIndex = mText.find(".");
        if (decimalIndex != null &&
            mText.length() - (decimalIndex as Number) - 1 >= mDecimalPlaces) {
            return;
        }
        var maximumLength = mMaximumScaled.format("%d").length() +
            (mDecimalPlaces > 0 ? 1 : 0);
        if (mText.length() < maximumLength) {
            mText += digit.format("%d");
        }
        mError = false;
    }

    function appendDecimal() as Void {
        if (mDecimalPlaces == 0) { return; }
        if (mFresh) {
            mText = "0.";
            mFresh = false;
        } else if (mText.find(".") == null) {
            mText += ".";
        }
        mError = false;
    }

    function backspace() as Void {
        mFresh = false;
        if (mText.length() > 0) {
            mText = mText.substring(0, mText.length() - 1);
        }
        mError = false;
    }

    function getValidValue() as Numeric? {
        if (mText.length() == 0 || mText == "0.") { return null; }
        if (mDecimalPlaces == 0) {
            var integerValue = mText.toNumber();
            return integerValue >= mMinimumScaled &&
                integerValue <= mMaximumScaled ? integerValue : null;
        }
        var scaled = (mText.toFloat() * mScale + 0.5f).toNumber();
        if (scaled < mMinimumScaled || scaled > mMaximumScaled) { return null; }
        return scaled.toFloat() / mScale.toFloat();
    }

    function showRangeError() as Void { mError = true; }
    function getText() as String { return mText; }
    function getSelectedAction() as Number { return mSelectedAction; }

    function getOkAction() as Number {
        return mDecimalPlaces > 0 ? ACTION_DECIMAL_OK : ACTION_INTEGER_OK;
    }

    function moveSelection(delta as Number) as Void {
        var count = getOkAction() + 1;
        mSelectedAction = (mSelectedAction + delta + count) % count;
    }

    function setGeometry(width as Number, height as Number) as Void {
        mWidth = width;
        mHeight = height;
        mGridTop = (mHeight * 30 / 100).toNumber();
    }

    function getActionAt(x as Number, y as Number) as Number? {
        if (x < 0 || x >= mWidth || y < mGridTop || y >= mHeight) {
            return null;
        }
        var rows = mDecimalPlaces > 0 ? 5 : 4;
        var row = ((y - mGridTop) * rows /
            (mHeight - mGridTop)).toNumber();
        if (mDecimalPlaces > 0 && row == 4) { return ACTION_DECIMAL_OK; }
        return row * 3 + (x * 3 / mWidth).toNumber();
    }

    function onUpdate(dc as Dc) as Void {
        setGeometry(dc.getWidth(), dc.getHeight());
        var dark = System.getDeviceSettings().isNightModeEnabled;
        var background = dark ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var foreground = dark ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var secondary = dark ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;

        dc.setColor(foreground, background);
        dc.clear();
        dc.drawText(mWidth / 2, 4, Graphics.FONT_SMALL, mTitle,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(mWidth / 2, (mGridTop * 35 / 100).toNumber(),
            Graphics.FONT_NUMBER_MEDIUM, mText.length() == 0 ? "--" : mText,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(mError ? foreground : secondary,
            Graphics.COLOR_TRANSPARENT);
        var range = formatScaled(mMinimumScaled) + "-" +
            formatScaled(mMaximumScaled);
        dc.drawText(mWidth / 2,
            mGridTop - dc.getFontHeight(Graphics.FONT_XTINY) - 3,
            Graphics.FONT_XTINY, mError ? "ENTER " + range : range,
            Graphics.TEXT_JUSTIFY_CENTER);

        var rows = mDecimalPlaces > 0 ? 5 : 4;
        var cellHeight = (mHeight - mGridTop) / rows;
        for (var action = 0; action <= getOkAction(); action += 1) {
            var x = (action % 3) * mWidth / 3;
            var y = mGridTop + (action / 3) * cellHeight;
            var width = mWidth / 3;
            if (mDecimalPlaces > 0 && action == ACTION_DECIMAL_OK) {
                x = 0;
                width = mWidth;
            }
            drawCell(dc, action, actionLabel(action), x, y, width,
                cellHeight, foreground, secondary, background);
        }
    }

    private function drawCell(
        dc as Dc,
        action as Number,
        label as String,
        x as Number,
        y as Number,
        width as Number,
        height as Number,
        foreground as Graphics.ColorValue,
        secondary as Graphics.ColorValue,
        background as Graphics.ColorValue
    ) as Void {
        if (action == mSelectedAction) {
            dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + 2, y + 2, width - 4, height - 4);
            dc.setColor(background, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(secondary, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(x + 2, y + 2, width - 4, height - 4);
            dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(x + width / 2,
            y + (height - dc.getFontHeight(Graphics.FONT_MEDIUM)) / 2,
            Graphics.FONT_MEDIUM, label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function formatScaled(value as Number) as String {
        if (mDecimalPlaces == 0) { return value.format("%d"); }
        return (value / mScale).format("%d") + "." +
            (value % mScale).format("%d");
    }

    private function actionLabel(action as Number) as String {
        if (action < 9) { return (action + 1).format("%d"); }
        if (action == ACTION_BACKSPACE) { return "<"; }
        if (action == ACTION_ZERO) { return "0"; }
        if (action == ACTION_DECIMAL && mDecimalPlaces > 0) { return "."; }
        return "OK";
    }
}

class ReusableNumericKeypadDelegate extends WatchUi.BehaviorDelegate {
    private var mKeypad as ReusableNumericKeypadBase;
    private var mListener as ReusableNumericKeypadListener;

    function initialize(
        keypad as ReusableNumericKeypadBase,
        listener as ReusableNumericKeypadListener
    ) {
        BehaviorDelegate.initialize();
        mKeypad = keypad;
        mListener = listener;
    }

    // Touch must be handled by coordinates. Do not implement onSelect(): Garmin
    // can map a tap to onSelect(), which would activate the button focus (OK is
    // initially selected) instead of the cell that was touched.
    function onTap(event as ClickEvent) as Boolean {
        var coordinates = event.getCoordinates();
        var action = mKeypad.getActionAt(coordinates[0], coordinates[1]);
        if (action != null) { activate(action as Number); }
        return true;
    }

    // These preserve optional swipe-based focus movement on touch devices.
    function onNextPage() as Boolean {
        mKeypad.moveSelection(1);
        refreshKeypad();
        return true;
    }

    function onPreviousPage() as Boolean {
        mKeypad.moveSelection(-1);
        refreshKeypad();
        return true;
    }

    // Raw key handling keeps physical Enter separate from touchscreen taps.
    function onKey(event as KeyEvent) as Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            activate(mKeypad.getSelectedAction());
        } else if (key == WatchUi.KEY_DOWN) {
            mKeypad.moveSelection(1);
            refreshKeypad();
        } else if (key == WatchUi.KEY_UP) {
            mKeypad.moveSelection(-1);
            refreshKeypad();
        } else {
            return false;
        }
        return true;
    }

    function onBack() as Boolean {
        mListener.onNumericKeypadCancelled();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    private function activate(action as Number) as Void {
        if (action < 9) {
            mKeypad.appendDigit(action + 1);
        } else if (action == mKeypad.ACTION_BACKSPACE) {
            mKeypad.backspace();
        } else if (action == mKeypad.ACTION_ZERO) {
            mKeypad.appendDigit(0);
        } else if (action == mKeypad.ACTION_DECIMAL &&
            action != mKeypad.getOkAction()) {
            mKeypad.appendDecimal();
        } else {
            var value = mKeypad.getValidValue();
            if (value == null) {
                mKeypad.showRangeError();
                refreshKeypad();
                return;
            }
            mListener.onNumericKeypadAccepted(value as Numeric);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }
        refreshKeypad();
    }

    private function refreshKeypad() as Void {
        // requestUpdate() can leave a pushed settings view visually stale on
        // physical Edge hardware. Replace only the current top view instead.
        WatchUi.switchToView(mKeypad, self, WatchUi.SLIDE_IMMEDIATE);
    }
}
