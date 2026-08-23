import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class SettingsMenu extends WatchUi.Menu2 {
    var guidanceItem;

    function initialize(title) {
        Menu2.initialize({ :title => title });
        guidanceItem = null;
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var mSection;
    var mMenu;

    function initialize(section, menu) {
        Menu2InputDelegate.initialize();
        mSection = section;
        mMenu = menu;
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (mSection == :root) {
            openSection(id);
        } else if (item instanceof ToggleMenuItem) {
            var enabled = item.isEnabled();
            if (enabled && requiresValidRange(id) && !sectionRangeIsValid()) {
                item.setEnabled(false);
                item.setSubLabel("SET VALID LIMITS");
                enabled = false;
            }
            Application.Properties.setValue(propertyKey(id), enabled);
            getApp().settingsChanged();
        } else {
            openNumber(id, item);
        }
    }

    private function openSection(id) {
        var menu = buildSection(id);
        WatchUi.pushView(menu, new SettingsMenuDelegate(id, menu), WatchUi.SLIDE_LEFT);
    }

    private function openNumber(id, item) {
        var spec = numberSpec(id) as Array<Object>;
        var key = propertyKey(id);
        var current = numberProperty(key, 0);
        applyCompanionLimit(id, spec);
        var pad = new NumericKeypad(spec[0] as String, spec[1] as Number,
            spec[2] as Number, current);
        WatchUi.pushView(pad, new NumericKeypadDelegate(pad, key, item,
            spec[3] as String, id, mMenu.guidanceItem), WatchUi.SLIDE_LEFT);
    }

    private function buildSection(id) {
        var menu;
        if (id == :power) {
            menu = new SettingsMenu("Power");
            addToggle(menu, "Guidance", :powerEnabled);
            addNumber(menu, "Lower limit", :powerLow, " W");
            addNumber(menu, "Upper limit", :powerHigh, " W");
            addNumber(menu, "Warning delay", :powerDelay, " s");
            addNumber(menu, "Moving average", :powerAverageSeconds, " s");
        } else if (id == :heartRate) {
            menu = new SettingsMenu("Heart Rate");
            addToggle(menu, "Guidance", :hrEnabled);
            addNumber(menu, "Ceiling", :hrCeiling, " bpm");
            addNumber(menu, "Warning delay", :hrDelay, " s");
        } else if (id == :cadence) {
            menu = new SettingsMenu("Cadence");
            addToggle(menu, "Guidance", :cadenceEnabled);
            addNumber(menu, "Lower limit", :cadenceLow, " rpm");
            addNumber(menu, "Upper limit", :cadenceHigh, " rpm");
            addNumber(menu, "Warning delay", :cadenceDelay, " s");
        } else if (id == :fueling) {
            menu = new SettingsMenu("Fueling");
            addToggle(menu, "Show target", :carbsEnabled);
            addNumber(menu, "Carbohydrate rate", :carbRate, " g/h");
        } else {
            menu = new SettingsMenu("Drift");
            addToggle(menu, "Show drift", :driftEnabled);
            addNumber(menu, "Warning threshold", :driftThreshold, "%");
        }
        return menu;
    }

    private function addToggle(menu, label, id) {
        var enabled = Application.Properties.getValue(propertyKey(id)) == true;
        var status = requiresValidRange(id) && !rangeIsValid(id)
            ? "SET VALID LIMITS" : null;
        var item = new WatchUi.ToggleMenuItem(label, status, id, enabled, null);
        menu.guidanceItem = item;
        menu.addItem(item);
    }

    private function addNumber(menu, label, id, unit) {
        var value = numberProperty(propertyKey(id), 0);
        menu.addItem(new WatchUi.MenuItem(label, value.format("%d") + unit, id, null));
    }

    private function numberProperty(key, fallback) {
        var value = Application.Properties.getValue(key);
        return value instanceof Number ? value : fallback;
    }

    private function propertyKey(id) {
        if (id == :powerEnabled) { return "powerEnabled"; }
        if (id == :powerLow) { return "powerLow"; }
        if (id == :powerHigh) { return "powerHigh"; }
        if (id == :powerDelay) { return "powerDelay"; }
        if (id == :powerAverageSeconds) { return "powerAverageSeconds"; }
        if (id == :hrEnabled) { return "hrEnabled"; }
        if (id == :hrCeiling) { return "hrCeiling"; }
        if (id == :hrDelay) { return "hrDelay"; }
        if (id == :cadenceEnabled) { return "cadenceEnabled"; }
        if (id == :cadenceLow) { return "cadenceLow"; }
        if (id == :cadenceHigh) { return "cadenceHigh"; }
        if (id == :cadenceDelay) { return "cadenceDelay"; }
        if (id == :carbsEnabled) { return "carbsEnabled"; }
        if (id == :carbRate) { return "carbRate"; }
        if (id == :driftEnabled) { return "driftEnabled"; }
        return "driftThreshold";
    }

    // [title, minimum, maximum, display unit]
    private function numberSpec(id) {
        if (id == :powerLow) { return ["Power lower (W)", 1, 1000, " W"]; }
        if (id == :powerHigh) { return ["Power upper (W)", 1, 1000, " W"]; }
        if (id == :powerDelay) { return ["Power delay (s)", 0, 120, " s"]; }
        if (id == :powerAverageSeconds) { return ["Power average (s)", 1, 30, " s"]; }
        if (id == :hrCeiling) { return ["HR ceiling", 1, 250, " bpm"]; }
        if (id == :hrDelay) { return ["HR delay (s)", 0, 120, " s"]; }
        if (id == :cadenceLow) { return ["Cadence lower", 1, 250, " rpm"]; }
        if (id == :cadenceHigh) { return ["Cadence upper", 1, 250, " rpm"]; }
        if (id == :cadenceDelay) { return ["Cadence delay (s)", 0, 120, " s"]; }
        if (id == :carbRate) { return ["Carbs (g/h)", 1, 200, " g/h"]; }
        return ["Drift threshold", 0, 25, "%"];
    }

    private function applyCompanionLimit(id, spec as Array<Object>) {
        if (id == :powerLow || id == :cadenceLow) {
            var upper = numberProperty(propertyKey(id == :powerLow ? :powerHigh : :cadenceHigh), 0);
            if (upper > 0 && upper - 1 < (spec[2] as Number)) { spec[2] = upper - 1; }
        } else if (id == :powerHigh || id == :cadenceHigh) {
            var lower = numberProperty(propertyKey(id == :powerHigh ? :powerLow : :cadenceLow), 0);
            if (lower > 0 && lower + 1 > (spec[1] as Number)) { spec[1] = lower + 1; }
        }
    }

    private function requiresValidRange(id) {
        return id == :powerEnabled || id == :cadenceEnabled;
    }

    private function rangeIsValid(id) {
        var power = id == :powerEnabled;
        return isValidTargetRange(
            numberProperty(power ? "powerLow" : "cadenceLow", 0),
            numberProperty(power ? "powerHigh" : "cadenceHigh", 0));
    }

    private function sectionRangeIsValid() {
        return rangeIsValid(mSection == :power ? :powerEnabled : :cadenceEnabled);
    }
}

class NumericKeypad extends WatchUi.View {
    var mTitle;
    var mMinimum;
    var mMaximum;
    var mModel;
    var mError = false;
    var mWidth = 246;
    var mHeight = 322;
    var mGridTop = 96;

    function initialize(title, minimum, maximum, current) {
        View.initialize();
        mTitle = title; mMinimum = minimum; mMaximum = maximum;
        mModel = new NumericInputModel(minimum, maximum, current);
    }

    function appendDigit(digit) {
        mModel.appendDigit(digit);
        mError = false;
    }

    function backspace() {
        mModel.backspace();
        mError = false;
    }

    function value() {
        return mModel.value();
    }

    function showError() { mError = true; }
    function selectedAction() { return mModel.selectedAction(); }

    function moveSelection(delta) {
        mModel.moveSelection(delta);
    }

    function actionAt(x, y) {
        return mModel.actionAt(x, y, mWidth, mHeight, mGridTop);
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth(); var height = dc.getHeight();
        mWidth = width; mHeight = height;
        mGridTop = (height * 30 / 100).toNumber();
        var dark = System.getDeviceSettings().isNightModeEnabled;
        var background = dark ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var foreground = dark ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var secondary = dark ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
        dc.setColor(foreground, background); dc.clear();
        dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 4, Graphics.FONT_SMALL, mTitle, Graphics.TEXT_JUSTIFY_CENTER);
        var displayText = mModel.text();
        dc.drawText(width / 2, (mGridTop * 35 / 100).toNumber(), Graphics.FONT_NUMBER_MEDIUM,
            displayText.length() == 0 ? "--" : displayText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(mError ? foreground : secondary, Graphics.COLOR_TRANSPARENT);
        var hint = mError ? "ENTER " + mMinimum.format("%d") + "-" + mMaximum.format("%d")
            : mMinimum.format("%d") + "-" + mMaximum.format("%d");
        dc.drawText(width / 2, mGridTop - dc.getFontHeight(Graphics.FONT_XTINY) - 3,
            Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_CENTER);

        var labels = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "<", "0", "OK"];
        var cellHeight = (height - mGridTop) / 4; var cellWidth = width / 3;
        for (var row = 0; row < 4; row += 1) {
            for (var column = 0; column < 3; column += 1) {
                var action = row * 3 + column;
                var x = column * cellWidth; var y = mGridTop + row * cellHeight;
                if (action == selectedAction()) {
                    dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
                    dc.fillRectangle(x + 2, y + 2, cellWidth - 4, cellHeight - 4);
                    dc.setColor(background, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(secondary, Graphics.COLOR_TRANSPARENT);
                    dc.drawRectangle(x + 2, y + 2, cellWidth - 4, cellHeight - 4);
                    dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
                }
                dc.drawText(x + cellWidth / 2, y + (cellHeight - dc.getFontHeight(Graphics.FONT_MEDIUM)) / 2,
                    Graphics.FONT_MEDIUM, labels[action], Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}

class NumericKeypadDelegate extends WatchUi.BehaviorDelegate {
    var mPad;
    var mKey;
    var mItem;
    var mUnit;
    var mId;
    var mGuidanceItem;
    function initialize(pad, key, item, unit, id, guidanceItem) {
        BehaviorDelegate.initialize();
        mPad = pad;
        mKey = key;
        mItem = item;
        mUnit = unit;
        mId = id;
        mGuidanceItem = guidanceItem;
    }

    function onTap(event as ClickEvent) as Boolean {
        var coordinates = event.getCoordinates();
        var index = mPad.actionAt(coordinates[0], coordinates[1]);
        if (index != null) { activate(index as Number); }
        return true;
    }

    function onNextPage() as Boolean {
        mPad.moveSelection(1);
        refreshPad();
        return true;
    }

    function onPreviousPage() as Boolean {
        mPad.moveSelection(-1);
        refreshPad();
        return true;
    }

    // Keep physical activation separate from touch. Implementing onSelect()
    // can cause a touchscreen tap to activate the focused OK cell instead.
    function onKey(event as KeyEvent) as Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            activate(mPad.selectedAction());
        } else if (key == WatchUi.KEY_DOWN) {
            mPad.moveSelection(1);
            refreshPad();
        } else if (key == WatchUi.KEY_UP) {
            mPad.moveSelection(-1);
            refreshPad();
        } else {
            return false;
        }
        return true;
    }

    private function activate(index) {
        if (index < 9) {
            mPad.appendDigit(index + 1);
            refreshPad();
        } else if (index == 9) {
            mPad.backspace();
            refreshPad();
        } else if (index == 10) {
            mPad.appendDigit(0);
            refreshPad();
        } else {
            var value = mPad.value();
            if (value == null || !validCompanion(value)) { mPad.showError(); refreshPad(); }
            else {
                Application.Properties.setValue(mKey, value);
                mItem.setSubLabel(value.format("%d") + mUnit);
                refreshRangeStatus();
                getApp().settingsChanged();
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            }
        }
    }

    private function validCompanion(value) {
        if (mId == :powerLow) {
            return acceptsTargetBound(value, numberProperty("powerHigh"), true);
        } else if (mId == :powerHigh) {
            return acceptsTargetBound(value, numberProperty("powerLow"), false);
        } else if (mId == :cadenceLow) {
            return acceptsTargetBound(value, numberProperty("cadenceHigh"), true);
        } else if (mId == :cadenceHigh) {
            return acceptsTargetBound(value, numberProperty("cadenceLow"), false);
        }
        return true;
    }

    private function numberProperty(key) {
        var value = Application.Properties.getValue(key);
        return value instanceof Number ? value : 0;
    }

    private function refreshRangeStatus() {
        if (mGuidanceItem == null) { return; }
        var power = mId == :powerLow || mId == :powerHigh;
        var valid = isValidTargetRange(
            numberProperty(power ? "powerLow" : "cadenceLow"),
            numberProperty(power ? "powerHigh" : "cadenceHigh"));
        mGuidanceItem.setSubLabel(valid ? null : "SET VALID LIMITS");
    }

    private function refreshPad() {
        // Data-field settings views are not guaranteed to repaint in response
        // to requestUpdate(). Replacing only the top view forces an immediate
        // redraw while preserving the settings section below it on the stack.
        WatchUi.switchToView(mPad, self, WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

function buildSettingsMenu() {
    var menu = new SettingsMenu("Aerobic Guard");
    menu.addItem(new WatchUi.MenuItem("Power", null, :power, null));
    menu.addItem(new WatchUi.MenuItem("Heart Rate", null, :heartRate, null));
    menu.addItem(new WatchUi.MenuItem("Cadence", null, :cadence, null));
    menu.addItem(new WatchUi.MenuItem("Fueling", null, :fueling, null));
    menu.addItem(new WatchUi.MenuItem("Drift", null, :drift, null));
    return menu;
}
