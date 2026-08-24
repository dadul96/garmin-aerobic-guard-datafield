import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

class DashboardRenderer {
    var mLayout as DashboardLayout;
    var mGreen;
    var mAmber;
    var mRed;
    var mFullScreenRequired;
    var mPowerShort;
    var mHeartRateShort;
    var mCadenceShort;
    var mMaximumLabel;
    var mGramsShort;
    var mMilesPerHour;
    var mKilometersPerHour;
    var mUnavailable;
    var mUnavailableTime;

    function initialize() {
        mLayout = new DashboardLayout();
        // Essential meaning is carried by position, posts, and text. These
        // deliberately bright fills are redundant sunlight-visible accents.
        mGreen = Graphics.createColor(255, 0, 205, 0);
        mAmber = Graphics.createColor(255, 255, 185, 0);
        mRed = Graphics.createColor(255, 255, 65, 65);
        // Custom Graphics drawing APIs require Strings, not ResourceIds.
        // Resolve once here to keep the once-per-second path allocation-light.
        mFullScreenRequired = resourceText(Rez.Strings.FullScreenRequired);
        mPowerShort = resourceText(Rez.Strings.PowerShort);
        mHeartRateShort = resourceText(Rez.Strings.HeartRateShort);
        mCadenceShort = resourceText(Rez.Strings.CadenceShort);
        mMaximumLabel = resourceText(Rez.Strings.MaximumLabel);
        mGramsShort = resourceText(Rez.Strings.GramsShort);
        mMilesPerHour = resourceText(Rez.Strings.MilesPerHour);
        mKilometersPerHour = resourceText(Rez.Strings.KilometersPerHour);
        mUnavailable = resourceText(Rez.Strings.Unavailable);
        mUnavailableTime = resourceText(Rez.Strings.UnavailableTime);
    }

    function draw(dc as Dc, state as DisplayState, settings as SettingsModel) {
        var width = dc.getWidth();
        mLayout.configure(width, dc.getHeight(), settings.powerEnabled,
            settings.hrEnabled, settings.cadenceEnabled);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();

        if (!mLayout.isFullScreen) {
            centeredText(dc, width / 2, dc.getHeight() / 2,
                Graphics.FONT_MEDIUM, mFullScreenRequired,
                Graphics.COLOR_BLACK);
            return;
        }

        if (settings.powerEnabled) { drawPower(dc, width, state, settings); }
        if (settings.hrEnabled) { drawHeartRate(dc, width, state, settings); }
        if (settings.cadenceEnabled) { drawCadence(dc, width, state, settings); }
        drawFooter(dc, width, state, settings);
    }

    private function drawPower(dc, width, state as DisplayState,
            settings as SettingsModel) {
        var y = mLayout.powerY;
        var height = mLayout.powerHeight;
        var scaleMin = settings.powerLow * 0.8;
        var scaleMax = settings.powerHigh * 1.2;
        var color = rangeColor(state.power, settings.powerLow,
            settings.powerHigh, mRed);
        drawRangeBar(dc, y, height, width, state.power, scaleMin, scaleMax,
            settings.powerLow, settings.powerHigh, color);
        drawHugeValue(dc, y, height - scaled(20), width, state.power, null,
            Graphics.FONT_NUMBER_HOT);
        text(dc, scaled(8), y + height - scaled(36), labelFont(),
            mPowerShort,
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, scaled(8), y + height - scaled(18), smallFont(),
            powerAverageLabel(settings.powerAverageSeconds),
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, width - scaled(8), y + height - scaled(27), labelFont(),
            settings.powerLow.format("%d") + "-" +
                settings.powerHigh.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT, Graphics.COLOR_BLACK);
        drawAverageMarker(dc, state.averagePower, scaleMin, scaleMax, y,
            height, width);
    }

    private function drawHeartRate(dc, width, state as DisplayState,
            settings as SettingsModel) {
        var y = mLayout.hrY;
        var height = mLayout.hrHeight;
        var hasScale = settings.hrEnabled && state.hrMin != null
            && state.hrMax != null;
        drawCeilingBar(dc, y, height, width, state.heartRate, state.hrMin,
            state.hrMax, settings.hrCeiling, hasScale,
            state.heartRate != null && state.heartRate > settings.hrCeiling
                ? mRed : mGreen);
        drawHugeValue(dc, y, height - scaled(20), width, state.heartRate, null,
            Graphics.FONT_NUMBER_HOT);
        text(dc, scaled(8), y + height - scaled(19), labelFont(),
            mHeartRateShort,
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, width - scaled(8), y + height - scaled(19), labelFont(),
            mMaximumLabel + " " +
                settings.hrCeiling.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT, Graphics.COLOR_BLACK);
        if (hasScale) {
            drawAverageMarker(dc, state.averageHeartRate, state.hrMin,
                state.hrMax, y, height, width);
        }
    }

    private function drawCadence(dc, width, state as DisplayState,
            settings as SettingsModel) {
        var y = mLayout.cadenceY;
        var height = mLayout.cadenceHeight;
        var scaleMin = settings.cadenceLow * 0.8;
        var scaleMax = settings.cadenceHigh * 1.2;
        var color = rangeColor(state.cadence, settings.cadenceLow,
            settings.cadenceHigh, mAmber);
        drawRangeBar(dc, y, height, width, state.cadence, scaleMin, scaleMax,
            settings.cadenceLow, settings.cadenceHigh, color);
        drawHugeValue(dc, y, height - scaled(19), width, state.cadence, null,
            Graphics.FONT_NUMBER_HOT);
        text(dc, scaled(8), y + height - scaled(19), labelFont(),
            mCadenceShort,
            Graphics.TEXT_JUSTIFY_LEFT, Graphics.COLOR_BLACK);
        text(dc, width - scaled(8), y + height - scaled(19), labelFont(),
            settings.cadenceLow.format("%d") + "-" +
                settings.cadenceHigh.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT, Graphics.COLOR_BLACK);
        drawAverageMarker(dc, state.averageCadence, scaleMin, scaleMax, y,
            height, width);
    }

    private function drawRangeBar(dc, y, height, width, value, minimum,
            maximum, low, high, color) {
        startBand(dc, y, height, width);
        if (maximum <= minimum) { return; }
        if (value != null) {
            var x = position(value, minimum, maximum, 0, width);
            var fillWidth = value < minimum ? scaled(14) : x;
            if (fillWidth > 0) { fill(dc, 0, y, fillWidth, height, color); }
        }
        drawTargetPost(dc, position(low, minimum, maximum, 0, width), y, height);
        drawTargetPost(dc, position(high, minimum, maximum, 0, width), y, height);
        if (value != null) {
            drawOffScale(dc, y, height, value, minimum, maximum, width);
        }
        outlineBand(dc, y, height, width);
    }

    private function drawCeilingBar(dc, y, height, width, value, minimum,
            maximum, ceiling, enabled, color) {
        startBand(dc, y, height, width);
        if (!enabled || maximum <= minimum) { return; }
        if (value != null) {
            var x = position(value, minimum, maximum, 0, width);
            if (x > 0) { fill(dc, 0, y, x, height, color); }
        }
        drawTargetPost(dc, position(ceiling, minimum, maximum, 0, width), y, height);
        if (value != null) {
            drawOffScale(dc, y, height, value, minimum, maximum, width);
        }
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
        thickLine(dc, x, y + height - scaled(22), x, y + height - scaled(2),
            Graphics.COLOR_BLACK, scaled(5));
    }

    // A white knockout keeps the bottom-edge average marker distinct when it
    // coincides with a target post or dark text.
    private function drawAverageMarker(dc, average, minimum, maximum, y,
            height, width) {
        if (average == null || maximum <= minimum) { return; }
        var markerSize = scaled(10);
        var x = position(average, minimum, maximum, scaled(8), width - scaled(9));
        var markerTop = y + height - markerSize - scaled(3);
        for (var row = 0; row <= markerSize; row += 1) {
            var halfWidth = scaled(8) - (row * scaled(8) / markerSize).toNumber();
            thickLine(dc, x - halfWidth, markerTop + row,
                x + halfWidth, markerTop + row, Graphics.COLOR_WHITE, 1);
        }
        markerTop += scaled(2);
        var innerSize = scaled(6);
        for (var innerRow = 0; innerRow <= innerSize; innerRow += 1) {
            var innerHalfWidth = scaled(5) - (innerRow * scaled(5) / innerSize).toNumber();
            thickLine(dc, x - innerHalfWidth, markerTop + innerRow,
                x + innerHalfWidth, markerTop + innerRow,
                Graphics.COLOR_BLACK, 1);
        }
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

    private function drawFooter(dc, width, state as DisplayState,
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
                formatInteger(state.carbs) + mGramsShort);
            x += carbWidth;
            remainingWidth -= carbWidth;
            remainingCount -= 1;
            thickLine(dc, x, y, x, y + height, Graphics.COLOR_BLACK, 1);
        }
        var speedWidth = remainingWidth / remainingCount;
        footerSpeed(dc, x, speedWidth, y, height, state.speed, statute);
        x += speedWidth;
        thickLine(dc, x, y, x, y + height, Graphics.COLOR_BLACK, 1);
        footerValue(dc, x, width - x, y, height, formatTime(state.elapsed));
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
        var unit = statute ? mMilesPerHour : mKilometersPerHour;
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

    private function scaled(value) { return (value * mLayout.scale / 100).toNumber(); }
    private function labelFont() { return mLayout.scale >= 150 ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL; }
    private function smallFont() {
        return mLayout.scale >= 150 ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
    }

    private function fillOutwardArrow(dc, x, y, pointsRight, color) {
        var arrowSize = scaled(9);
        for (var offset = 0; offset <= arrowSize; offset += 1) {
            var arrowX = pointsRight ? x - arrowSize + offset : x + arrowSize - offset;
            var half = offset * scaled(8) / arrowSize;
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
        return value == null ? mUnavailable : value.format("%d");
    }

    private function formatSpeed(value, statute) {
        if (value == null) { return mUnavailable; }
        return statute
            ? (value * 2.236936).format("%.1f")
            : (value * 3.6).format("%.1f");
    }

    private function formatTime(seconds) {
        if (seconds == null) { return mUnavailableTime; }
        var hours = (seconds / 3600).toNumber();
        var minutes = ((seconds % 3600) / 60).toNumber();
        var secs = (seconds % 60).toNumber();
        return hours.format("%d") + ":" + minutes.format("%02d") + ":" +
            secs.format("%02d");
    }
}
