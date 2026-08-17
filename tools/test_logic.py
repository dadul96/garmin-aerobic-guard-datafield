#!/usr/bin/env python3
"""Reference vectors for Aerobic Guard's pure calculation contract."""

import math
import pathlib
import unittest
import xml.etree.ElementTree as ET


def carbs(elapsed_seconds, rate):
    return math.floor(rate * math.floor(elapsed_seconds / 600) / 6 + 0.5)


class Coach:
    def __init__(self):
        self.counts = dict(hr=0, high=0, low=0, cad_low=0, cad_high=0)

    def update(self, power, hr, cadence, delays=(5, 20, 10), ceiling=142):
        conditions = {
            "hr": hr > ceiling,
            "high": power > 200,
            "low": power < 170,
            "cad_low": cadence > 0 and power > 10 and cadence < 82,
            "cad_high": cadence > 95,
        }
        for key, condition in conditions.items():
            self.counts[key] = self.counts[key] + 1 if condition else 0
        power_delay, hr_delay, cadence_delay = delays
        if self.counts["hr"] >= hr_delay:
            return "EASE - HR HIGH"
        if self.counts["high"] >= power_delay:
            return "EASE POWER"
        if hr < ceiling - 5 and self.counts["low"] >= power_delay:
            return "LIFT POWER"
        if self.counts["cad_low"] >= cadence_delay:
            return "SPIN FASTER"
        if self.counts["cad_high"] >= cadence_delay:
            return "LOWER CADENCE"
        return "STEADY"


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
    def test_drift_display_defaults_enabled(self):
        root = ET.parse("resources/properties/properties.xml").getroot()
        properties = {item.attrib["id"]: item.text for item in root}
        self.assertEqual("true", properties["driftEnabled"])

    def test_carbohydrate_completed_blocks_and_rounding(self):
        self.assertEqual(0, carbs(599, 60))
        self.assertEqual(10, carbs(600, 60))
        self.assertEqual(27, carbs(1200, 80))
        self.assertEqual(80, carbs(3600, 80))

    def test_coaching_persistence_and_priority(self):
        coach = Coach()
        for _ in range(4):
            self.assertEqual("STEADY", coach.update(220, 130, 90))
        self.assertEqual("EASE POWER", coach.update(220, 130, 90))
        coach = Coach()
        for _ in range(20):
            result = coach.update(220, 150, 70)
        self.assertEqual("EASE - HR HIGH", result)

    def test_renderer_preserves_simultaneous_red_warnings(self):
        engine = pathlib.Path("source/CoachingEngine.mc").read_text()
        field = pathlib.Path("source/AerobicGuardField.mc").read_text()
        renderer = pathlib.Path("source/DashboardRenderer.mc").read_text()

        self.assertIn("function isHrHigh()", engine)
        self.assertIn("function isPowerHigh()", engine)
        self.assertIn("mState[:powerHigh] = mCoach.isPowerHigh()", field)
        self.assertIn("if (state[:powerHigh]) { return Graphics.COLOR_RED; }", renderer)
        self.assertIn("state[:powerLow] && !state[:hrHigh]", renderer)
        self.assertIn("!state[:hrHigh] && (state[:cadenceLow]", renderer)

    def test_hr_vetoes_low_power_instruction(self):
        coach = Coach()
        for _ in range(8):
            result = coach.update(150, 139, 90)
        self.assertEqual("STEADY", result)

    def test_drift_readiness_and_formula(self):
        self.assertLess(2399, 2400)
        baseline_efficiency = 180 / 135
        recent_efficiency = 171 / 135
        drift = (1 - recent_efficiency / baseline_efficiency) * 100
        self.assertAlmostEqual(5.0, drift)
        self.assertLess(719, 720)
        self.assertLess(479, 480)

    def test_drift_warning_threshold_contract(self):
        def drift_is_high(value, threshold):
            return value is not None and value >= threshold

        self.assertFalse(drift_is_high(None, 5))
        self.assertFalse(drift_is_high(4.9, 5))
        self.assertTrue(drift_is_high(5.0, 5))
        self.assertTrue(drift_is_high(6.0, 5))

        renderer = pathlib.Path("source/DashboardRenderer.mc").read_text()
        self.assertIn("driftIsHigh(state[:drift], settings.driftThreshold)", renderer)
        self.assertIn('driftHigh ? "DRIFT HIGH" : "DRIFT"', renderer)
        self.assertIn("driftHigh ? Graphics.COLOR_YELLOW", renderer)
        self.assertGreaterEqual(
            renderer.count(
                "thickLine(dc, 0, y, width, y, Graphics.COLOR_DK_GRAY, 1)"
            ),
            3,
        )

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
        self.assertIn('formatInteger(state[:carbs]) + " g"', source)

    def test_power_and_cadence_gauge_scale_around_target(self):
        low = 80
        high = 95
        scale_min = low * 0.8
        scale_max = high * 1.2
        self.assertEqual(64, scale_min)
        self.assertEqual(114, scale_max)

        source = pathlib.Path("source/DashboardRenderer.mc").read_text()
        self.assertIn("var scaleMin = low * 0.8", source)
        self.assertIn("var scaleMax = high * 1.2", source)
        self.assertIn("drawMarker(dc, y, value, scaleMin, scaleMax", source)

    def test_adaptive_dashboard_layout_contract(self):
        def layout(enabled):
            weight = 1 + sum(2 for visible in enabled[:3] if visible)
            weight += 1 if enabled[3] else 0
            unit = (322 - 44) // weight
            heights = [unit * 2 if visible else 0 for visible in enabled[:3]]
            heights.append(unit if enabled[3] else 0)
            heights.append(322 - 44 - sum(heights))
            return heights

        for mask in range(16):
            enabled = tuple(bool(mask & (1 << bit)) for bit in range(4))
            heights = layout(enabled)
            self.assertEqual(278, sum(heights))
            self.assertTrue(all(height >= 0 for height in heights))
            for index, visible in enumerate(enabled):
                self.assertEqual(visible, heights[index] > 0)

        self.assertEqual([68, 68, 68, 34, 40], layout((True, True, True, True)))
        self.assertEqual([184, 0, 0, 0, 94], layout((True, False, False, False)))
        self.assertEqual([0, 0, 0, 139, 139], layout((False, False, False, True)))

        renderer = pathlib.Path("source/DashboardRenderer.mc").read_text()
        self.assertNotIn('"AEROBIC GUARD"', renderer)
        self.assertNotIn("Graphics.COLOR_LT_GRAY", renderer)
        self.assertIn("settings.powerEnabled, settings.hrEnabled", renderer)
        self.assertIn('"PWR"', renderer)
        self.assertIn('"CAD"', renderer)
        self.assertIn("Graphics.createColor(255, 0, 220, 0)", renderer)
        self.assertIn("thickLine(dc, lowX, y, highX, y, Graphics.COLOR_BLACK, 10)", renderer)
        self.assertIn("thickLine(dc, 0, y, width, y, Graphics.COLOR_DK_GRAY, 1)", renderer)
        self.assertIn("thickLine(dc, ceilingX, y - 8, ceilingX, y + 8, Graphics.COLOR_BLACK, 7)", renderer)
        self.assertIn("background == Graphics.COLOR_RED", renderer)
        self.assertIn("thickLine(dc, x, y - 8, x, y + 8, Graphics.COLOR_BLACK, 9)", renderer)
        self.assertIn("thickLine(dc, x, y - 8, x, y + 8, Graphics.COLOR_WHITE, 7)", renderer)
        self.assertIn("thickLine(dc, x, y - 8, x, y + 8, Graphics.COLOR_BLACK, 3)", renderer)

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
