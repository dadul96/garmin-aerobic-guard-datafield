import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

class DashboardRenderer {
    var mLayout as DashboardLayout;
    var mGreen;
    var mAmber;
    var mRed;

    function initialize() {
        mLayout = new DashboardLayout();
        // Essential meaning is carried by position, posts, and text. These
        // deliberately bright fills are redundant sunlight-visible accents.
        mGreen = Graphics.createColor(255, 0, 205, 0);
        mAmber = Graphics.createColor(255, 255, 185, 0);
        mRed = Graphics.createColor(255, 255, 65, 65);
    }

    function draw(dc as Dc, state as Dictionary, settings as SettingsModel) {
        var width = dc.getWidth();
        mLayout.configure(dc.getHeight(), settings.powerEnabled,
            settings.hrEnabled, settings.cadenceEnabled);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();

        if (settings.powerEnabled) { drawPower(dc, width, state, settings); }
        if (settings.hrEnabled) { drawHeartRate(dc, width, state, settings); }
        if (settings.cadenceEnabled) { drawCadence(dc, width, state, settings); }
        drawFooter(dc, width, state, settings);
    }

    private function drawPower(dc, width, state as Dictionary,
            settings as SettingsModel) {
        var y = mLayout.powerY;
        var height = mLayout.powerHeight;
        var scaleMin = settings.powerLow * 0.8;
        var scaleMax = settings.powerHigh * 1.2;
        var color = rangeColor(state[:power], settings.powerLow,
            settings.powerHigh, mRed);
        drawRangeBar(dc, y, height, width, state[:power], scaleMin, scaleMax,
            settings.powerLow, settings.powerHigh, color);
        drawHugeValue(dc, y, height - 20, width, state[:power], null,
            Graphics.FONT_NUMBER_HOT);
        text(dc, 8, y + height - 36, Graphics.FONT_SMALL, "PWR",
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, 8, y + height - 18, Graphics.FONT_SMALL,
            powerAverageLabel(settings.powerAverageSeconds),
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, width - 8, y + height - 27, Graphics.FONT_SMALL,
            settings.powerLow.format("%d") + "-" +
                settings.powerHigh.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT, Graphics.COLOR_BLACK);
    }

    private function drawHeartRate(dc, width, state as Dictionary,
            settings as SettingsModel) {
        var y = mLayout.hrY;
        var height = mLayout.hrHeight;
        var hasScale = settings.hrEnabled && state[:hrMin] != null
            && state[:hrMax] != null;
        drawCeilingBar(dc, y, height, width, state[:heartRate], state[:hrMin],
            state[:hrMax], settings.hrCeiling, hasScale,
            state[:heartRate] != null && state[:heartRate] > settings.hrCeiling
                ? mRed : mGreen);
        drawHugeValue(dc, y, height - 20, width, state[:heartRate], null,
            Graphics.FONT_NUMBER_HOT);
        text(dc, 8, y + height - 19, Graphics.FONT_SMALL, "HR",
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, width - 8, y + height - 19, Graphics.FONT_SMALL,
            "MAX " + settings.hrCeiling.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT, Graphics.COLOR_BLACK);
    }

    private function drawCadence(dc, width, state as Dictionary,
            settings as SettingsModel) {
        var y = mLayout.cadenceY;
        var height = mLayout.cadenceHeight;
        var scaleMin = settings.cadenceLow * 0.8;
        var scaleMax = settings.cadenceHigh * 1.2;
        var color = rangeColor(state[:cadence], settings.cadenceLow,
            settings.cadenceHigh, mAmber);
        drawRangeBar(dc, y, height, width, state[:cadence], scaleMin, scaleMax,
            settings.cadenceLow, settings.cadenceHigh, color);
        drawHugeValue(dc, y, height - 19, width, state[:cadence], null,
            Graphics.FONT_NUMBER_HOT);
        text(dc, 8, y + height - 19, Graphics.FONT_SMALL, "CAD",
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, width - 8, y + height - 19, Graphics.FONT_SMALL,
            settings.cadenceLow.format("%d") + "-" +
                settings.cadenceHigh.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT, Graphics.COLOR_BLACK);
    }

    private function drawRangeBar(dc, y, height, width, value, minimum,
            maximum, low, high, color) {
        startBand(dc, y, height, width);
        if (value == null || maximum <= minimum) { return; }
        var x = position(value, minimum, maximum, 0, width);
        var fillWidth = value < minimum ? 14 : x;
        if (fillWidth > 0) { fill(dc, 0, y, fillWidth, height, color); }
        drawTargetPost(dc, position(low, minimum, maximum, 0, width), y, height);
        drawTargetPost(dc, position(high, minimum, maximum, 0, width), y, height);
        drawOffScale(dc, y, height, value, minimum, maximum, width);
        outlineBand(dc, y, height, width);
    }

    private function drawCeilingBar(dc, y, height, width, value, minimum,
            maximum, ceiling, enabled, color) {
        startBand(dc, y, height, width);
        if (!enabled || value == null || maximum <= minimum) { return; }
        var x = position(value, minimum, maximum, 0, width);
        if (x > 0) { fill(dc, 0, y, x, height, color); }
        drawTargetPost(dc, position(ceiling, minimum, maximum, 0, width), y, height);
        drawOffScale(dc, y, height, value, minimum, maximum, width);
        outlineBand(dc, y, height, width);
    }

    private function startBand(dc, y, height, width) {
        fill(dc, 0, y, width, height, Graphics.COLOR_WHITE);
        outlineBand(dc, y, height, width);
    }

    private function outlineBand(dc, y, height, width) {
        thickLine(dc, 0, y, width, y, Graphics.COLOR_BLACK, 2);
        thickLine(dc, 0, y + height - 1, width, y + height - 1,
            Graphics.COLOR_BLACK, 2);
    }

    private function drawTargetPost(dc, x, y, height) {
        thickLine(dc, x, y + height - 22, x, y + height - 2,
            Graphics.COLOR_BLACK, 5);
    }

    private function drawOffScale(dc, y, height, value, minimum, maximum, width) {
        if (value < minimum) {
            fillOutwardArrow(dc, 0, y + height / 2, false, Graphics.COLOR_BLACK);
        } else if (value > maximum) {
            fillOutwardArrow(dc, width - 1, y + height / 2, true,
                Graphics.COLOR_BLACK);
        }
    }

    private function drawHugeValue(dc, y, height, width, value, unit,
            preferredFont) {
        var valueText = formatInteger(value);
        var font = preferredFont;
        var unitWidth = unit == null ? 0
            : dc.getTextWidthInPixels(unit, Graphics.FONT_SMALL) + 8;
        if (dc.getTextWidthInPixels(valueText, font) + unitWidth > width - 16
                || dc.getFontHeight(font) > height - 4) {
            font = Graphics.FONT_NUMBER_MEDIUM;
        }
        var valueWidth = dc.getTextWidthInPixels(valueText, font);
        var groupWidth = valueWidth + unitWidth;
        var left = (width - groupWidth) / 2;
        var centerY = y + height / 2;
        text(dc, left, centerY - dc.getFontHeight(font) / 2, font, valueText,
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        if (unit != null) {
            text(dc, left + valueWidth + 8,
                centerY - dc.getFontHeight(Graphics.FONT_SMALL) / 2,
                Graphics.FONT_SMALL, unit, Graphics.TEXT_JUSTIFY_LEFT,
                Graphics.COLOR_BLACK);
        }
    }

    private function drawFooter(dc, width, state as Dictionary,
            settings as SettingsModel) {
        var y = mLayout.footerY;
        var height = mLayout.footerHeight;
        fill(dc, 0, y, width, height, Graphics.COLOR_WHITE);
        var count = settings.carbsEnabled ? 3 : 2;
        var statute = System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
        var remainingWidth = width;
        var remainingCount = count;
        var x = 0;
        if (settings.carbsEnabled) {
            var carbWidth = remainingWidth / remainingCount;
            footerValue(dc, x, carbWidth, y, height,
                formatInteger(state[:carbs]) + "g");
            x += carbWidth;
            remainingWidth -= carbWidth;
            remainingCount -= 1;
            thickLine(dc, x, y, x, y + height, Graphics.COLOR_BLACK, 1);
        }
        var speedWidth = remainingWidth / remainingCount;
        footerSpeed(dc, x, speedWidth, y, height, state[:speed], statute);
        x += speedWidth;
        thickLine(dc, x, y, x, y + height, Graphics.COLOR_BLACK, 1);
        footerValue(dc, x, width - x, y, height, formatTime(state[:elapsed]));
        thickLine(dc, 0, y, width, y, Graphics.COLOR_BLACK, 2);
    }

    private function footerValue(dc, x, width, y, height, value) {
        var font = Graphics.FONT_MEDIUM;
        if (dc.getTextWidthInPixels(value, font) > width - 8) {
            font = Graphics.FONT_SMALL;
        }
        centeredText(dc, x + width / 2, y + height / 2, font, value,
            Graphics.COLOR_BLACK);
    }

    private function footerSpeed(dc, x, width, y, height, value, statute) {
        var valueText = formatSpeed(value, statute);
        var unit = statute ? "mph" : "km/h";
        var valueFont = Graphics.FONT_MEDIUM;
        var unitFont = Graphics.FONT_XTINY;
        var unitWidth = dc.getTextWidthInPixels(unit, unitFont);
        var valueWidth = dc.getTextWidthInPixels(valueText, valueFont);
        if (valueWidth + unitWidth + 4 > width - 8) {
            valueFont = Graphics.FONT_SMALL;
            valueWidth = dc.getTextWidthInPixels(valueText, valueFont);
        }
        var left = x + (width - valueWidth - unitWidth - 4) / 2;
        var centerY = y + height / 2;
        text(dc, left, centerY - dc.getFontHeight(valueFont) / 2,
            valueFont, valueText, Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, left + valueWidth + 4,
            centerY - dc.getFontHeight(unitFont) / 2, unitFont, unit,
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
    }

    private function rangeColor(value, low, high, highColor) {
        if (value == null) { return mGreen; }
        if (value < low) { return mAmber; }
        if (value > high) { return highColor; }
        return mGreen;
    }

    private function powerAverageLabel(seconds) {
        return seconds.format("%d") + "s";
    }

    private function fillOutwardArrow(dc, x, y, pointsRight, color) {
        for (var offset = 0; offset <= 9; offset += 1) {
            var arrowX = pointsRight ? x - 9 + offset : x + 9 - offset;
            var half = offset * 8 / 9;
            thickLine(dc, arrowX, y - half, arrowX, y + half, color, 1);
        }
    }

    private function fill(dc, x, y, width, height, color) {
        dc.setColor(color, color);
        dc.fillRectangle(x, y, width, height);
    }

    private function thickLine(dc, x1, y1, x2, y2, color, width) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(width);
        dc.drawLine(x1, y1, x2, y2);
        dc.setPenWidth(1);
    }

    private function centeredText(dc, x, centerY, font, value, color) {
        text(dc, x, centerY - dc.getFontHeight(font) / 2, font, value,
            Graphics.TEXT_JUSTIFY_CENTER, color);
    }

    private function text(dc, x, y, font, value, justify, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, value, justify);
    }

    private function position(value, minimum, maximum, left, right) {
        var clamped = value < minimum ? minimum : (value > maximum ? maximum : value);
        return left + ((right - left) * (clamped - minimum) / (maximum - minimum)).toNumber();
    }

    private function formatInteger(value) {
        return value == null ? "--" : value.format("%d");
    }

    private function formatSpeed(value, statute) {
        if (value == null) { return "--"; }
        return statute
            ? (value * 2.236936).format("%.1f")
            : (value * 3.6).format("%.1f");
    }

    private function formatTime(seconds) {
        if (seconds == null) { return "--:--:--"; }
        var hours = (seconds / 3600).toNumber();
        var minutes = ((seconds % 3600) / 60).toNumber();
        var secs = (seconds % 60).toNumber();
        return hours.format("%d") + ":" + minutes.format("%02d") + ":" +
            secs.format("%02d");
    }
}
