# Architecture

Aerobic Guard is a full-screen Connect IQ data field targeting the Edge 840.
The implementation keeps live collection, calculations, settings,
and rendering separate so the once-per-second path remains bounded and the
pure behavior can be tested.

## Runtime flow

`aerobic_guardApp` creates `AerobicGuardField`. Garmin normally calls the
field's `compute(info)` once per second and calls `onUpdate(dc)` when the field
must be drawn.

One-time setting initialization runs when Garmin requests the initial data-field
view, before `SettingsModel` is constructed. It does not run while Garmin is
constructing the separate on-device settings view. Runtime capability checks
and defensive property reads keep a profile API or migration failure contained.

`AerobicGuardField` performs these tasks:

- reads nullable activity values from `Activity.Info`;
- converts elapsed milliseconds to seconds;
- determines whether the activity timer is running;
- stores the filtered presentation power and other live metrics;
- asks `DashboardRenderer` to draw the latest state.

State is initialized before `compute()` because Garmin does not guarantee that
`compute()` precedes `onUpdate()`.

## Source ownership

- `AerobicGuardField.mc`: activity input collection and component orchestration.
- `SettingsModel.mc`: property loading, validation, and inactive handling for
  unconfigured guidance.
- `TargetRangeValidation.mc`: shared strict ordering rules for power and
  cadence targets, used by both runtime loading and the on-device settings UI.
- `ZoneDefaultsInitializer.mc`: one-time Garmin cycling Zone 2 import,
  cadence/carbohydrate product defaults, and persistent guards that prevent
  later automatic target changes.
- `SettingsMenu.mc`: on-device settings menus, toggles, and the integer keypad.
  Its keypad uses `BehaviorDelegate`, which inherits raw touch handling from
  `InputDelegate` while retaining device-independent Back behavior. Touch is
  handled only by coordinates; physical Up/Down moves a visible wrapping focus
  and Enter/Start activates it, allowing settings entry without touch.
  Successful edits refresh the visible menu row and notify the live field to
  reload validated properties. Digit edits replace only the active keypad view
  with an immediate transition to force repainting in the data-field settings
  runtime while preserving the underlying menu stack.
  Power and cadence keypads derive their allowed bounds from the companion
  value and revalidate it on save. Incomplete or invalid target pairs cannot
  enable guidance. No Garmin Connect/host settings resource is exposed.
- `CarbCalculator.mc`: completed-ten-minute-block carbohydrate calculation.
- `DashboardLayout.mc`: allocation-free Edge 840 geometry for equal-height
  enabled guidance bars and the compact telemetry rail. Hidden
  bars contribute their space equally to those that remain.
- `DashboardRenderer.mc`: the sunlight-oriented, full-screen Edge 840
  presentation using black/white primary contrast and redundant color accents.
- `PowerMovingAverage.mc`: bounded rolling filter used only for the displayed
  power number and gauge marker.
- `AerobicGuardTests.mc`: Garmin Run No Evil tests, excluded from production
  builds unless the unit-test compiler flag is used.

## Important boundaries

- The displayed power number and color-fill edge share the configured 1-30
  second moving average.
  Missing current power clears the filter and remains visibly unavailable. The
  power bar shows the window as `Ns`, including `1s`, beneath its `PWR` label.
- Power and cadence bars draw from `lower × 0.8` through `upper × 1.2` and
  clamp only their fill edges; numeric measurements remain unchanged.
- Power, HR, and cadence bars are shown only when their guidance is enabled.
  Visible bars divide the metric region equally and retain power/HR/cadence
  order. Carbohydrate telemetry follows its display toggle; speed and elapsed
  time always remain.
- Each metric region is the gauge: color fills from its drawing minimum through
  the visually clamped current value. Fill color reflects the live numeric
  relationship to its target. Values below the drawing minimum receive a fixed-width
  amber stub because a proportional fill at zero would otherwise be invisible.
- Garmin's activity average for each primary metric is shown as a small black
  downward triangle at the bottom of the same scale. A white knockout keeps it
  distinct from nearby target posts and text. Missing averages are not drawn,
  and off-scale averages are visually clamped to the scale endpoint.
- Target ranges use two bold posts, the HR ceiling uses one post, and visually
  clamped values add filled outward arrows. The color-to-white edge alone marks
  the current position; numeric values remain real.
- HR remains ceiling-only; its fill turns red only above the configured ceiling.
- Fueling is a passive cumulative target with no alerts or consumption logging.
- The footer divides equally among its visible values: carbs/speed/time when
  fueling is enabled and speed/time when disabled. Speed follows Garmin's
  distance-unit setting, converts m/s to km/h or mph, and renders the unit in a
  deliberately extra-small font beside the larger number.
- Rendering never invents missing sensor values or physiological HR ranges.
- Garmin zone-derived power and HR targets are imported at most once. Existing
  non-zero targets win, and failed or malformed lookups remain zero permanently
  unless the rider configures them.
- When Garmin power-zone thresholds are unavailable, a positive cycling FTP
  supplies a standard 56-75% Zone 2 fallback with inward whole-watt rounding.
  A versioned corrective migration applies it only while both stored power
  limits are still zero.
- Cadence and carbohydrate settings receive separate one-time product defaults
  of 80-95 rpm and 60 g/h; existing non-zero values remain authoritative.
- The application does not record custom FIT fields or use networking.
