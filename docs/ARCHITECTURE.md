# Architecture

Aerobic Guard is a full-screen Connect IQ data field targeting the Edge 840.
The implementation keeps live collection, coaching, calculations, settings,
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
- sends current values to the coaching and drift components;
- stores raw current power for display without smoothing;
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
- `CoachingEngine.mc`: deterministic priority and persistence state machine.
- `CarbCalculator.mc`: completed-ten-minute-block carbohydrate calculation.
- `DriftCalculator.mc`: warm-up, baseline aggregates, bounded rolling recent
  window, sample validity, and drift calculation.
- `DashboardLayout.mc`: allocation-free weighted geometry for visible riding
  cards. Guidance cards receive twice the height of context/footer cards, and
  disabled cards receive no space.
- `DashboardRenderer.mc`: the adaptive, full-screen Edge 840 presentation.
- `PowerMovingAverage.mc`: bounded rolling filter used only for the displayed
  power number and gauge marker.
- `AerobicGuardTests.mc`: Garmin Run No Evil tests, excluded from production
  builds unless the unit-test compiler flag is used.

## Important boundaries

- The displayed power number and gauge marker share the configured 1-30 second
  moving average. Coaching and drift continue to consume raw `currentPower`.
  Missing current power clears the filter and remains visibly unavailable. The
  power card shows the active window as `AVG Ns` beneath its `PWR` label.
- Power and cadence gauges draw from `lower × 0.8` through `upper × 1.2` and
  clamp only their visual markers; numeric measurements remain unchanged.
- Power, HR, and cadence guidance toggles also control riding-card visibility.
  Drift and carbohydrate tiles follow their existing display toggles. Remaining
  cards expand; speed and elapsed time remain visible in every configuration.
- Card warning colors follow the persisted coaching state rather than raw
  threshold crossings. The engine exposes each persisted condition separately
  from its single prioritized coaching message, allowing simultaneous HR-high
  and power-high cards to remain red. HR-high suppresses lower-priority yellow
  power-low and cadence cards. Current-value markers still update every second,
  subject to the configured power moving average.
- HR is ceiling-only and can veto `LIFT POWER` near the ceiling.
- Drift accepts only positive power/HR samples while the activity is running.
- A ready drift value at or above the configured threshold highlights only the
  drift context tile and labels it `DRIFT HIGH`; it does not replace the main
  coaching state.
- Drift memory is bounded: baseline data is aggregated and the recent window
  uses ten fixed one-minute buckets.
- Fueling is a passive cumulative target with no alerts or consumption logging.
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
