#!/usr/bin/env python3
"""Reference vectors for Aerobic Guard's pure calculation contract."""

import math
import pathlib
import unittest
import xml.etree.ElementTree as ET


def carbs(elapsed_seconds, rate):
    return math.floor(rate * math.floor(elapsed_seconds / 600) / 6 + 0.5)


class NumericInput:
    def __init__(self, minimum, maximum, current):
        self.minimum = minimum
        self.maximum = maximum
        self.text = str(current) if current > 0 else ""
        self.fresh = True
        self.selected_action = 11

    def append(self, digit):
        if self.fresh:
            self.text = ""
            self.fresh = False
        if len(self.text) < len(str(self.maximum)):
            self.text += str(digit)

    def backspace(self):
        self.fresh = False
        self.text = self.text[:-1]

    def value(self):
        if not self.text:
            return None
        value = int(self.text)
        return value if self.minimum <= value <= self.maximum else None

    def move_selection(self, delta):
        self.selected_action = (self.selected_action + delta + 12) % 12

    @staticmethod
    def action_at(x, y, width=246, height=322, grid_top=96):
        if (width <= 0 or height <= grid_top or x < 0 or x >= width
                or y < grid_top or y >= height):
            return None
        column = int(x * 3 / width)
        row = int((y - grid_top) * 4 / (height - grid_top))
        return row * 3 + column


class ContractTests(unittest.TestCase):
    def test_carbohydrate_completed_blocks_and_rounding(self):
        self.assertEqual(0, carbs(599, 60))
        self.assertEqual(10, carbs(600, 60))
        self.assertEqual(27, carbs(1200, 80))
        self.assertEqual(80, carbs(3600, 80))

    def test_renderer_uses_live_range_colors(self):
        renderer = pathlib.Path("source/DashboardRenderer.mc").read_text()
        self.assertIn("rangeColor(state[:power]", renderer)
        self.assertIn("rangeColor(state[:cadence]", renderer)
        self.assertIn("if (value < low) { return mAmber; }", renderer)
        self.assertIn("if (value > high) { return highColor; }", renderer)

    def test_numeric_input_editing_and_validation(self):
        value = NumericInput(1, 1000, 170)
        for digit in (1, 8, 0, 9, 9):
            value.append(digit)
        self.assertEqual("1809", value.text)
        self.assertIsNone(value.value())
        value.backspace()
        self.assertEqual(180, value.value())

        bounded = NumericInput(10, 20, 0)
        self.assertIsNone(bounded.value())
        bounded.append(9)
        self.assertIsNone(bounded.value())

    def test_numeric_keypad_hit_mapping(self):
        self.assertIsNone(NumericInput.action_at(123, 50))
        self.assertIsNone(NumericInput.action_at(-1, 124))
        self.assertIsNone(NumericInput.action_at(246, 124))
        self.assertEqual(0, NumericInput.action_at(41, 124))
        self.assertEqual(2, NumericInput.action_at(205, 124))
        self.assertEqual(9, NumericInput.action_at(41, 294))
        self.assertEqual(10, NumericInput.action_at(123, 294))
        self.assertEqual(11, NumericInput.action_at(205, 294))

    def test_numeric_keypad_button_focus_wraps(self):
        value = NumericInput(0, 1000, 170)
        self.assertEqual(11, value.selected_action)
        value.move_selection(1)
        self.assertEqual(0, value.selected_action)
        value.move_selection(-1)
        value.move_selection(-1)
        self.assertEqual(10, value.selected_action)

    def test_numeric_keypad_delegate_and_save_refresh(self):
        source = pathlib.Path("source/SettingsMenu.mc").read_text()
        keypad_delegate = source.split(
            "class NumericKeypadDelegate", 1
        )[1]
        self.assertIn(
            "class NumericKeypadDelegate extends WatchUi.BehaviorDelegate",
            source,
        )
        self.assertIn("function onTap(event as ClickEvent)", source)
        self.assertIn("function onKey(event as KeyEvent)", source)
        self.assertIn("key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START", source)
        self.assertIn("key == WatchUi.KEY_DOWN", source)
        self.assertIn("key == WatchUi.KEY_UP", source)
        self.assertNotIn("function onSelect(", keypad_delegate)
        self.assertIn("mItem.setSubLabel", source)
        self.assertIn("getApp().settingsChanged()", source)
        self.assertIn("WatchUi.switchToView(mPad, self, WatchUi.SLIDE_IMMEDIATE)", source)
        self.assertNotIn("mError = false; WatchUi.requestUpdate()", source)
        self.assertIn("applyCompanionLimit(id, spec)", source)
        self.assertIn("!validCompanion(value)", source)
        self.assertIn('"SET VALID LIMITS"', source)

        exported = pathlib.Path(
            "reusable_numeric_keypad/ReusableNumericKeypad.mc"
        ).read_text()
        self.assertIn(
            "WatchUi.switchToView(mKeypad, self, WatchUi.SLIDE_IMMEDIATE)",
            exported,
        )
        self.assertNotIn("WatchUi.requestUpdate()", exported)

    def test_target_ranges_are_strict_and_settings_are_on_device_only(self):
        validation = pathlib.Path("source/TargetRangeValidation.mc").read_text()
        settings_model = pathlib.Path("source/SettingsModel.mc").read_text()

        self.assertIn("lower > 0 && upper > lower", validation)
        self.assertIn("editingLower ? value < companion : value > companion", validation)
        self.assertIn("isValidTargetRange(low, high)", settings_model)
        self.assertFalse(pathlib.Path("resources/settings/settings.xml").exists())

        strings = ET.parse("resources/strings/strings.xml").getroot()
        self.assertEqual(["AppName"], [item.attrib["id"] for item in strings])

    def test_defaults_do_not_mutate_settings_launch(self):
        app_source = pathlib.Path("source/aerobic-guardApp.mc").read_text()
        field_source = pathlib.Path("source/AerobicGuardField.mc").read_text()
        on_start = app_source.split("function onStart", 1)[1].split("function onStop", 1)[0]
        initial_view = app_source.split("function getInitialView", 1)[1].split(
            "function settingsChanged", 1
        )[0]
        self.assertNotIn("initializeOnce", on_start)
        self.assertNotIn("ZoneDefaultsInitializer().initializeOnce", initial_view)
        self.assertIn("AdvisoryDefaultsInitializer().initializeOnce", initial_view)
        self.assertIn("ZoneDefaultsInitializer().initializeOnce", field_source)
        self.assertIn("mSettings.reload()", field_source)

    def test_renderer_does_not_put_units_in_numeric_format_pattern(self):
        source = pathlib.Path("source/DashboardRenderer.mc").read_text()
        self.assertNotIn('format("%d g")', source)
        self.assertIn('formatInteger(state[:carbs]) + "g"', source)
        self.assertNotIn("drift", source.lower())

    def test_power_and_cadence_gauge_scale_around_target(self):
        low = 80
        high = 95
        scale_min = low * 0.8
        scale_max = high * 1.2
        self.assertEqual(64, scale_min)
        self.assertEqual(114, scale_max)

        source = pathlib.Path("source/DashboardRenderer.mc").read_text()
        self.assertIn("var scaleMin = settings.powerLow * 0.8", source)
        self.assertIn("var scaleMax = settings.powerHigh * 1.2", source)
        self.assertIn("drawRangeBar(dc, y, height, width, state[:power]", source)
        self.assertIn("state[:averagePower]", source)
        self.assertIn("state[:averageHeartRate]", source)
        self.assertIn("state[:averageCadence]", source)
        self.assertIn("drawAverageMarker", source)

    def test_fixed_live_bar_dashboard_contract(self):
        layout = pathlib.Path("source/DashboardLayout.mc").read_text()
        self.assertNotIn("banner", layout.lower())
        self.assertIn("var visibleCount = 0", layout)
        self.assertIn("remainingHeight / remainingCount", layout)
        self.assertIn("if (showPower)", layout)
        self.assertIn("if (showHr)", layout)
        self.assertIn("if (showCadence)", layout)

        renderer = pathlib.Path("source/DashboardRenderer.mc").read_text()
        self.assertNotIn('"AEROBIC GUARD"', renderer)
        self.assertIn('"PWR"', renderer)
        self.assertIn('return seconds.format("%d") + "s"', renderer)
        self.assertIn('"CAD"', renderer)
        self.assertIn("Graphics.FONT_NUMBER_HOT", renderer)
        self.assertNotIn("Graphics.FONT_TINY", renderer)
        self.assertEqual(1, renderer.count("Graphics.FONT_XTINY"))
        self.assertIn("drawRangeBar", renderer)
        self.assertIn("drawCeilingBar", renderer)
        self.assertIn("drawTargetPost", renderer)
        self.assertNotIn("fillDownMarker", renderer)
        self.assertIn("private function drawAverageMarker", renderer)
        self.assertIn("fillOutwardArrow", renderer)
        self.assertIn("var count = settings.carbsEnabled ? 3 : 2", renderer)
        self.assertIn("var speedWidth = remainingWidth / remainingCount", renderer)
        self.assertIn("var font = Graphics.FONT_MEDIUM", renderer)
        self.assertIn("var fillWidth = value < minimum ? 14 : x", renderer)
        self.assertIn("System.UNIT_STATUTE", renderer)
        self.assertIn('? "mph" : "km/h"', renderer)
        self.assertIn("drawHugeValue(dc, y, height - 20, width, state[:power], null", renderer)
        self.assertNotIn('"TARGET "', renderer)
        self.assertNotIn('"CEILING "', renderer)

    def test_drift_is_removed_from_product_surface(self):
        paths = [
            "source/AerobicGuardField.mc",
            "source/SettingsModel.mc",
            "source/SettingsMenu.mc",
            "source/DashboardRenderer.mc",
            "resources/properties/properties.xml",
        ]
        for path in paths:
            self.assertNotIn("drift", pathlib.Path(path).read_text().lower())
        self.assertFalse(pathlib.Path("source/DriftCalculator.mc").exists())

    def test_coaching_is_removed_from_product_surface(self):
        paths = [
            "source/AerobicGuardField.mc",
            "source/SettingsModel.mc",
            "source/SettingsMenu.mc",
            "source/DashboardRenderer.mc",
            "resources/properties/properties.xml",
        ]
        for path in paths:
            source = pathlib.Path(path).read_text().lower()
            self.assertNotIn("coach", source)
            self.assertNotIn("warning delay", source)
        self.assertFalse(pathlib.Path("source/CoachingEngine.mc").exists())

    def test_power_zone_import_and_ftp_fallback_contract(self):
        source = pathlib.Path("source/ZoneDefaultsInitializer.mc").read_text()
        self.assertIn("validPowerThresholds", source)
        self.assertNotIn("zones[0] >= 0", source)
        self.assertIn("zones[1] >= 0", source)
        self.assertIn("Math.ceil(ftp * 0.56)", source)
        self.assertIn("Math.floor(ftp * 0.75)", source)
        self.assertIn("powerZoneFtpFallbackV5Initialized", source)
        self.assertNotIn("System.println", source)


if __name__ == "__main__":
    unittest.main()
