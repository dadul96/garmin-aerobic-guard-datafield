import Toybox.Graphics;
import Toybox.Lang;

function driftIsHigh(value, threshold) {
    return value != null && value >= threshold;
}

class DashboardRenderer {
    var mLayout as DashboardLayout;
    var mGreen;

    function initialize() {
        mLayout = new DashboardLayout();
        // Slightly darker than COLOR_GREEN so it retains shape in bright sun.
        mGreen = Graphics.createColor(255, 0, 220, 0);
    }

    function draw(dc as Dc, state as Dictionary, settings as SettingsModel) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var showContext = settings.driftEnabled || settings.carbsEnabled;
        mLayout.configure(height, settings.powerEnabled, settings.hrEnabled,
            settings.cadenceEnabled, showContext);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        drawCoach(dc, width, state[:coach]);

        if (mLayout.powerHeight > 0) {
            drawRangeCard(dc, mLayout.powerY, mLayout.powerHeight, width,
                "PWR", settings.powerLow.format("%d") + "-" + settings.powerHigh.format("%d"),
                state[:power], "W", settings.powerLow, settings.powerHigh,
                powerCardColor(state));
        }
        if (mLayout.hrHeight > 0) {
            drawHrCard(dc, mLayout.hrY, mLayout.hrHeight, width, state, settings,
                hrCardColor(state));
        }
        if (mLayout.cadenceHeight > 0) {
            drawRangeCard(dc, mLayout.cadenceY, mLayout.cadenceHeight, width,
                "CAD", settings.cadenceLow.format("%d") + "-" + settings.cadenceHigh.format("%d"),
                state[:cadence], "RPM", settings.cadenceLow, settings.cadenceHigh,
                cadenceCardColor(state));
        }
        if (showContext) {
            drawContext(dc, mLayout.contextY, mLayout.contextHeight, width, state, settings);
        }
        drawFooter(dc, mLayout.footerY, mLayout.footerHeight, width, state);
    }

    private function drawCoach(dc, width, coach) {
        var background = Graphics.COLOR_DK_GRAY;
        var foreground = Graphics.COLOR_WHITE;
        if (coach.equals("STEADY")) {
            background = mGreen; foreground = Graphics.COLOR_BLACK;
        } else if (coach.equals("EASE - HR HIGH") || coach.equals("EASE POWER")) {
            background = Graphics.COLOR_RED;
        } else if (coach.equals("LIFT POWER") || coach.equals("SPIN FASTER") || coach.equals("LOWER CADENCE")) {
            background = Graphics.COLOR_YELLOW; foreground = Graphics.COLOR_BLACK;
        }
        fill(dc, 0, 0, width, mLayout.bannerHeight, background);
        centeredText(dc, width / 2, mLayout.bannerHeight / 2,
            Graphics.FONT_MEDIUM, coach, foreground);
    }

    private function drawRangeCard(dc, y, height, width, label, target, value,
            unit, low, high, background) {
        var foreground = cardForeground(background);
        card(dc, y, height, width, background);
        text(dc, 8, y + 4, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_LEFT, foreground);
        text(dc, 52, y + 6, Graphics.FONT_TINY, target, Graphics.TEXT_JUSTIFY_LEFT, foreground);
        drawLargeValue(dc, y, height, width, value, unit, foreground);
        rangeGauge(dc, y + height - 10, value, low, high, width, foreground);
    }

    private function drawHrCard(dc, y, height, width, state as Dictionary,
            settings as SettingsModel, background) {
        var foreground = cardForeground(background);
        card(dc, y, height, width, background);
        text(dc, 8, y + 4, Graphics.FONT_SMALL, "HR", Graphics.TEXT_JUSTIFY_LEFT, foreground);
        text(dc, 44, y + 6, Graphics.FONT_TINY, "<=" + settings.hrCeiling.format("%d"),
            Graphics.TEXT_JUSTIFY_LEFT, foreground);
        drawLargeValue(dc, y, height, width, state[:heartRate], "BPM", foreground);
        if (state[:hrMin] == null || state[:hrMax] == null) {
            text(dc, 8, y + height - 18, Graphics.FONT_TINY, "NO ZONES",
                Graphics.TEXT_JUSTIFY_LEFT, foreground);
        } else {
            var limitColor = background == Graphics.COLOR_RED
                ? Graphics.COLOR_WHITE : Graphics.COLOR_RED;
            hrGauge(dc, y + height - 10, state[:heartRate], state[:hrMin], state[:hrMax],
                settings.hrCeiling, width, foreground, limitColor);
        }
    }

    private function drawLargeValue(dc, y, height, width, value, unit, color) {
        var valueFont = height >= 60 ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_MEDIUM;
        var unitWidth = dc.getTextWidthInPixels(unit, Graphics.FONT_TINY);
        var centerY = y + (height - 8) / 2;
        text(dc, width - 10, centerY - dc.getFontHeight(Graphics.FONT_TINY) / 2,
            Graphics.FONT_TINY, unit, Graphics.TEXT_JUSTIFY_RIGHT, color);
        text(dc, width - 15 - unitWidth, centerY - dc.getFontHeight(valueFont) / 2,
            valueFont, formatInteger(value), Graphics.TEXT_JUSTIFY_RIGHT, color);
    }

    private function rangeGauge(dc, y, value, low, high, width, foreground) {
        var left = 8; var right = width - 8;
        var scaleMin = low * 0.8;
        var scaleMax = high * 1.2;
        var lowX = position(low, scaleMin, scaleMax, left, right);
        var highX = position(high, scaleMin, scaleMax, left, right);
        thickLine(dc, left, y, right, y, foreground, 3);
        // The one-pixel black surround keeps green distinct from white cards.
        thickLine(dc, lowX, y, highX, y, Graphics.COLOR_BLACK, 10);
        thickLine(dc, lowX, y, highX, y, mGreen, 8);
        drawMarker(dc, y, value, scaleMin, scaleMax, left, right, foreground);
    }

    private function hrGauge(dc, y, value, minimum, maximum, ceiling, width,
            foreground, limitColor) {
        var left = 8; var right = width - 8;
        thickLine(dc, left, y, right, y, foreground, 3);
        var ceilingX = position(ceiling, minimum, maximum, left, right);
        thickLine(dc, ceilingX, y - 8, ceilingX, y + 8, Graphics.COLOR_BLACK, 7);
        thickLine(dc, ceilingX, y - 8, ceilingX, y + 8, limitColor, 5);
        drawMarker(dc, y, value, minimum, maximum, left, right, foreground);
    }

    private function drawMarker(dc, y, value, minimum, maximum, left, right, color) {
        if (value == null || maximum <= minimum) { return; }
        var x = position(value, minimum, maximum, left, right);
        // Keep the moving marker identical on every card: black center, white
        // halo, black outer edge. The halo provides contrast on red cards.
        thickLine(dc, x, y - 8, x, y + 8, Graphics.COLOR_BLACK, 9);
        thickLine(dc, x, y - 8, x, y + 8, Graphics.COLOR_WHITE, 7);
        thickLine(dc, x, y - 8, x, y + 8, Graphics.COLOR_BLACK, 3);
        if (value < minimum) {
            thickLine(dc, left, y, left + 7, y - 6, color, 3);
            thickLine(dc, left, y, left + 7, y + 6, color, 3);
        } else if (value > maximum) {
            thickLine(dc, right, y, right - 7, y - 6, color, 3);
            thickLine(dc, right, y, right - 7, y + 6, color, 3);
        }
    }

    private function drawContext(dc, y, height, width, state as Dictionary,
            settings as SettingsModel) {
        card(dc, y, height, width, Graphics.COLOR_WHITE);
        var driftHigh = driftIsHigh(state[:drift], settings.driftThreshold);
        var driftLabel = driftHigh ? "DRIFT HIGH" : "DRIFT";
        var driftBackground = driftHigh ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        if (settings.driftEnabled && settings.carbsEnabled) {
            contextTile(dc, 0, y, width / 2, height, driftLabel,
                formatFloat(state[:drift], "%+.1f%%"), driftBackground);
            contextTile(dc, width / 2, y, width - width / 2, height, "CARB",
                formatInteger(state[:carbs]) + " g", Graphics.COLOR_WHITE);
            divider(dc, width / 2, y, height);
        } else if (settings.driftEnabled) {
            contextTile(dc, 0, y, width, height, driftLabel,
                formatFloat(state[:drift], "%+.1f%%"), driftBackground);
        } else {
            contextTile(dc, 0, y, width, height, "CARB",
                formatInteger(state[:carbs]) + " g", Graphics.COLOR_WHITE);
        }
        thickLine(dc, 0, y, width, y, Graphics.COLOR_DK_GRAY, 1);
    }

    private function drawFooter(dc, y, height, width, state as Dictionary) {
        card(dc, y, height, width, Graphics.COLOR_WHITE);
        contextTile(dc, 0, y, width / 2, height, "SPD", formatSpeed(state[:speed]),
            Graphics.COLOR_WHITE);
        contextTile(dc, width / 2, y, width - width / 2, height, "TIME",
            formatTime(state[:elapsed]), Graphics.COLOR_WHITE);
        divider(dc, width / 2, y, height);
        thickLine(dc, 0, y, width, y, Graphics.COLOR_DK_GRAY, 1);
    }

    private function contextTile(dc, x, y, width, height, label, value, background) {
        fill(dc, x, y, width, height, background);
        var valueFont = height >= 55 ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
        text(dc, x + 7, y + 3, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        centeredText(dc, x + width / 2, y + height / 2 + 5, valueFont, value, Graphics.COLOR_BLACK);
    }

    private function powerCardColor(state as Dictionary) {
        if (state[:powerHigh]) { return Graphics.COLOR_RED; }
        if (state[:powerLow] && !state[:hrHigh]) { return Graphics.COLOR_YELLOW; }
        return Graphics.COLOR_WHITE;
    }

    private function hrCardColor(state as Dictionary) {
        return state[:hrHigh] ? Graphics.COLOR_RED : Graphics.COLOR_WHITE;
    }

    private function cadenceCardColor(state as Dictionary) {
        return !state[:hrHigh] && (state[:cadenceLow] || state[:cadenceHigh])
            ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
    }

    private function cardForeground(background) {
        return background == Graphics.COLOR_RED ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }

    private function card(dc, y, height, width, color) {
        fill(dc, 0, y, width, height, color);
        thickLine(dc, 0, y, width, y, Graphics.COLOR_DK_GRAY, 1);
    }

    private function divider(dc, x, y, height) {
        thickLine(dc, x, y, x, y + height, Graphics.COLOR_DK_GRAY, 1);
    }

    private function fill(dc, x, y, width, height, color) {
        dc.setColor(color, color); dc.fillRectangle(x, y, width, height);
    }

    private function thickLine(dc, x1, y1, x2, y2, color, width) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(width);
        dc.drawLine(x1, y1, x2, y2); dc.setPenWidth(1);
    }

    private function centeredText(dc, x, centerY, font, value, color) {
        text(dc, x, centerY - dc.getFontHeight(font) / 2, font, value,
            Graphics.TEXT_JUSTIFY_CENTER, color);
    }

    private function text(dc, x, y, font, value, justify, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT); dc.drawText(x, y, font, value, justify);
    }

    private function position(value, minimum, maximum, left, right) {
        var clamped = value < minimum ? minimum : (value > maximum ? maximum : value);
        return left + ((right - left) * (clamped - minimum) / (maximum - minimum)).toNumber();
    }

    private function formatInteger(value) { return value == null ? "--" : value.format("%d"); }
    private function formatFloat(value, pattern) { return value == null ? "--" : value.format(pattern); }
    private function formatSpeed(value) { return value == null ? "--" : (value * 3.6).format("%.1f"); }
    private function formatTime(seconds) {
        if (seconds == null) { return "--:--:--"; }
        var hours = (seconds / 3600).toNumber();
        var minutes = ((seconds % 3600) / 60).toNumber();
        var secs = (seconds % 60).toNumber();
        return hours.format("%d") + ":" + minutes.format("%02d") + ":" + secs.format("%02d");
    }
}
