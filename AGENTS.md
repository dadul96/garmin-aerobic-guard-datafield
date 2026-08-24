# Aerobic Guard — AGENTS.md

## Project overview

Aerobic Guard is a Connect IQ **Data Field** for long aerobic / endurance cycling rides. It is not a workout player and must not attempt to replace Garmin's native structured-workout experience.

The supported products are Garmin Edge 540/540 Solar, 550, 840/840 Solar, 850,
1040/1040 Solar, and 1050 with Connect IQ API 6.0.0 or newer. Do not broaden
declared product support unless explicitly requested.

The product goal is simple:

> Help the rider stay inside a sustainable aerobic envelope by showing live power, a heart-rate ceiling, cadence guidance, cumulative carbohydrate target, speed, and elapsed time on one calm, glanceable page.

Prefer an opinionated endurance-specific experience over a generic configurable cycling dashboard.

## Product contract

### Core metrics

Aerobic Guard uses these live activity values when available:

- Power: `Activity.Info.currentPower`
- Heart rate: `Activity.Info.currentHeartRate`
- Cadence: `Activity.Info.currentCadence`
- Speed: `Activity.Info.currentSpeed`
- Elapsed activity time: `Activity.Info.elapsedTime`
- Recording/timer state when needed to distinguish active recording from paused/off states

All `Activity.Info` values may be `null`. Null handling is mandatory. Never fabricate sensor values.

### Power

Power guidance uses a user-configured lower and upper limit.

On the first application start only, Aerobic Guard may initialize the power
limits from Garmin's configured cycling Power Zone 2. Use one watt above the
maximum Zone 1 threshold as the lower limit and the maximum Zone 2 threshold as
the upper limit. If Garmin returns no valid zone thresholds but supplies a
positive cycling FTP, fall back to Garmin's standard Zone 2 percentages: round
the 56% FTP lower boundary upward and the 75% FTP upper boundary downward to
whole watts. If neither source is valid, leave both limits at zero. Persist
completion of this initialization attempt and never automatically overwrite or
recalculate the limits afterward.

An existing installation affected by the original validator bug may perform
versioned corrective power-only import attempts. Run each only when both stored power
limits remain zero, persist a separate completion flag, and never overwrite a
non-zero rider setting. These migrations exist solely because the original
validator made unsupported assumptions about unused power-zone array elements
and did not yet support the approved FTP fallback.

The user may configure a 1-30 second moving-average filter for displayed power.
It defaults to 1 second (raw current power). Apply the same filtered value to
the power text and bar edge. A missing current sample must display as unavailable and
must not reuse an earlier average.

### Heart rate

Heart rate guidance is **ceiling-only**.

- The user configures one HR ceiling.
- There is no lower HR target.
- Aerobic Guard must never instruct the rider to increase heart rate.

On the first application start only, Aerobic Guard may initialize the HR
ceiling from Garmin's configured cycling maximum Zone 2 threshold. If valid
zone thresholds are unavailable, leave the ceiling at zero. Persist completion
of this initialization attempt and never automatically overwrite or
recalculate the ceiling afterward.

Use Garmin's cycling HR-zone thresholds for the HR graph drawing range:

```monkeyc
var zones = UserProfile.getHeartRateZones2(Activity.SPORT_CYCLING);
```

When a valid six-value array is returned:

- graph minimum = `zones[0]` (minimum Zone 1 threshold)
- graph maximum = `zones[5]` (maximum Zone 5 threshold)

The HR graph must therefore start at Garmin's configured cycling HR minimum rather than zero. The configured Aerobic Guard HR ceiling is drawn as the important visual boundary inside that range.

`getHeartRateZones2()` may return default sport zones or `null` on error. Validate the array before use. If a valid drawing range cannot be obtained, do not invent physiological HR limits. Continue to show numeric HR and the configured ceiling, and render a graceful reduced/fallback HR visualization.

The current HR marker may be visually clamped to the graph endpoints while the numeric current HR remains the real value.

Small Garmin zone-boundary ticks may be used if they improve readability, but the UI must not become a generic multi-zone chart. The Aerobic Guard HR ceiling remains the dominant boundary.

The project needs the appropriate `UserProfile` permission to read user profile/zone information.

### Cadence

Cadence guidance uses a user-configured lower and upper limit.

Cadence is advisory and lower priority than the HR ceiling and power guidance.
Do not interpret zero cadence while coasting as an instruction to pedal faster.

On the first application start, initialize cadence guidance to 80-95 rpm and
enable it. Preserve any existing non-zero cadence limits and never
automatically overwrite these values afterward.

### Fueling

Fueling is intentionally simple. Aerobic Guard does **not** tell the rider when to eat, what to eat, or how much to eat in the current moment.

The user configures a carbohydrate rate in grams per hour, for example `60 g/h`.

Every completed 10-minute block, update the cumulative amount of carbohydrate that should have been consumed by that elapsed point in the ride.

Use elapsed activity time (`Activity.Info.elapsedTime`) rather than timer time for this calculation unless the product requirements are explicitly changed.

Calculation:

```text
completedBlocks = floor(elapsedSeconds / 600)
carbsByNow = round(carbRateGramsPerHour * completedBlocks / 6)
```

Examples:

- 60 g/h -> 10 g at 10 min, 20 g at 20 min, 60 g at 60 min
- 80 g/h -> approximately 13 g at 10 min, 27 g at 20 min, 80 g at 60 min

The preferred UI label is **CARBS BY NOW** or another equally unambiguous label.

On the first application start, initialize the carbohydrate rate to 60 g/h and
enable its display. Preserve any existing non-zero rate and never automatically
overwrite it afterward. This is an opinionated product starting value, not an
individualized fueling prescription.

Do not implement:

- fueling notifications
- "fuel now" messages
- serving-size recommendations
- food logging
- water reminders
- hydration tracking

## UI and interaction

Design for a full-screen data-field page across the supported Edge products.
Non-full-screen placements show only `FULL SCREEN REQUIRED`.

Suggested information hierarchy:

1. Power value + target-range live bar
2. HR value + ceiling live bar using Garmin cycling-zone min/max as drawing limits
3. Cadence value + target-range live bar
4. Cumulative carbs-by-now + speed + elapsed time

A conceptual layout is:

```text
+----------------------------+
| POWER               187 W  |
| -------[====o====]-------  |
|          170-200 W         |
+----------------------------+
| HR                 137 bpm |
| -----------o-|-----------  |
| 92          142         184|
|             MAX            |
+----------------------------+
| CADENCE              89 rpm|
| -------[===o===]---------  |
|           82-95 rpm        |
+----------------------------+
| 80 g   28.6 km/h   01:23:41|
+----------------------------+
```

This ASCII layout is conceptual, not a pixel-perfect specification.

### Visual rules

- Optimize for sunlight readability and quick glances.
- Do not rely on color alone to communicate status.
- Keep text and markers legible at Edge 840 resolution.
- Avoid decorative complexity.
- The current power indicator should update every second using the configured
  moving-average window. Show `1s` for the raw one-second setting.
- Show the active moving-average window directly beneath the `PWR` label.
- Power and cadence live bars use 0.8 times the configured lower limit as
  the drawing minimum and 1.2 times the configured upper limit as the drawing
  maximum. Visually clamp the color-fill edge to those endpoints while
  keeping the displayed numeric measurement unchanged.
- Enabled power, HR, and cadence fields divide the available primary-metric
  area equally. Disabled guidance fields are absent and the remaining fields
  expand without changing their order.
- HR ceiling should be visually prominent.
- Missing sensor values must be clearly represented without misleading zeros.
- Speed follows Garmin's configured distance units and shows `km/h` or `mph`
  beside the numeric footer value.
- A power or cadence value below the drawing minimum uses a small fixed-width
  amber under-range stub so zero remains visibly below range even though its
  proportional bar fill would otherwise have zero width. This is range context,
  not a cadence instruction while coasting.
- Keep renderer/layout code separate from metric logic.

## Settings

Keep settings intentionally small.

Expected settings:

### Power

- enable power guidance
- lower power limit in watts
- upper power limit in watts
- displayed-power moving-average window in seconds (1-30, default 1)

### Heart rate

- enable HR guidance
- HR ceiling in bpm

HR graph min/max are automatic from Garmin cycling zones and are not normal user settings.

### Cadence

- enable cadence guidance
- lower cadence limit in rpm
- upper cadence limit in rpm

### Fueling

- enable carbohydrate target display
- carbohydrate rate in grams/hour

Do not add settings merely because they are easy to add. Prefer a small, coherent product.

The custom numeric keypad must show each digit/backspace edit immediately on
physical Edge hardware. Do not rely solely on `WatchUi.requestUpdate()` for a
pushed data-field settings view; use an immediate top-view replacement while
preserving the settings navigation stack when required by the device runtime.

If guidance settings are not configured, the app should fail gracefully and still show the live metric where useful. Do not silently invent personalized targets.

The one permitted automatic initialization is a first-start import of Garmin's
configured cycling Power Zone 2 bounds and maximum HR Zone 2 threshold. When
power-zone bounds are unavailable, a positive Garmin cycling FTP may instead
initialize power Zone 2 at 56-75% FTP using the rounding rule above. Valid
imports may enable their corresponding guidance. Preserve any existing non-zero
targets, record that initialization was attempted even when Garmin returns no
usable data, and never run the import again automatically.

Also initialize cadence guidance once to 80-95 rpm and carbohydrate display
once to 60 g/h. Preserve existing non-zero values and never automatically
reapply these defaults. These are explicit product defaults rather than
personalized targets.

## Scope and non-goals

Aerobic Guard is a live endurance-ride assistant.

Do **not** add the following unless the product requirements explicitly change:

- structured workout parsing or execution
- Intervals.icu integration
- Garmin workout-step integration
- networking, cloud sync, accounts, or companion services
- navigation
- route handling
- water/hydration tracking
- automatic fueling prescriptions
- automatic zone recalculation after the one-time first-start zone import
- dynamic modification of the user's HR or power targets
- generic configurable dashboard functionality unrelated to aerobic endurance
- FIT developer fields or custom FIT recording

### No FIT data

Aerobic Guard must **not** use `Toybox.FitContributor` and must not create, write, or register custom FIT developer fields.

Do not duplicate Garmin's existing power, HR, cadence, or post-ride analytics into custom FIT fields. Post-ride analysis belongs to Garmin and Intervals.icu.

The generic repository FIT analysis tools described later in this file may be used to inspect private test recordings when necessary, but they do not imply that Aerobic Guard writes FIT developer data.

## Connect IQ engineering rules

- App type: Connect IQ Data Field.
- Declared targets: Edge 540, 550, 840, 850, 1040, and 1050.
- Minimum API level: 6.0.0 or newer.
- Use `WatchUi.DataField`, not `SimpleDataField`, because the project requires custom full-screen drawing.
- `compute(info)` receives `Activity.Info` once per second under normal data-field operation. Keep computation bounded and lightweight.
- Initialize state outside `compute()`. Garmin does not guarantee that `compute()` runs before `onUpdate()`.
- Null-check all optional `Activity.Info` values.
- Keep metric collection, fueling calculations, settings,
  and rendering separated enough to test independently.
- Avoid unnecessary allocations in once-per-second hot paths.
- Prefer small fixed-size state over unbounded arrays.
- Do not use Sensor APIs that are invalid for data fields when the needed metric is already available through `Activity.Info`.
- Do not add permissions that are not required.
- Do not add `ActivityControl`, `Communications`, or `FitContributor` capabilities for the current product.
- Add the User Profile permission needed for Garmin HR-zone access.

## Implementation quality

- Favor small, readable Monkey C modules/classes with clear ownership.
- Keep calculations unit-testable where the Connect IQ test framework permits it.
- For tricky pure logic, add repository-side validators/tests when useful and wire them into `./tools/check`.
- Comments should explain intent, constraints, or non-obvious Garmin behavior, not narrate obvious code.
- Avoid premature framework-building. The app is deliberately small.
- Preserve established repository conventions and wrappers.
- Do not broaden device support while fixing unrelated issues.
- Do not silently change the product semantics in this file. If an implementation constraint conflicts with a requirement, report the conflict.

## Project documentation

Durable project documentation lives under `docs/`. Start with
`docs/README.md`, which indexes the available documents and their ownership.

- `docs/ARCHITECTURE.md` describes the implemented modules, runtime data flow,
  and important separation boundaries. Update it when module ownership, state
  flow, memory strategy, or a major integration boundary changes.
- `docs/DEVELOPMENT.md` describes repository commands, environment boundaries,
  settings workflow, and the implementation checklist. Update it when wrappers,
  supported development workflows, or configuration entry points change.
- `docs/TESTING.md` is the operational test guide, including the automated gate,
  test artifacts, and human simulator commands. Update it whenever tests,
  commands, expected output, or validation responsibilities change.
- `docs/DECISIONS.md` is the durable product and engineering decision log. Add a
  dated entry when a meaningful choice constrains future work, resolves a
  trade-off, deliberately defers work, or supersedes an earlier decision. State
  the decision, rationale, and consequences. Do not rewrite history when a
  decision changes; add a superseding entry instead. Do not use it as a task log.

`AGENTS.md` remains the product and engineering source of truth. Documentation
must not weaken or contradict it. When behavior or workflow changes, update the
relevant documentation in the same change rather than leaving future agents to
infer the new state from source code. Keep documentation scoped to the six
declared Edge products unless broader support is explicitly approved.

## Validation expectations

For substantive source/resource changes:

1. Run `./tools/garmin doctor` when environment health is relevant.
2. Run the appropriate build wrapper.
3. Run `./tools/check` before declaring the work complete.
4. Confirm `bin/app.prg` exists after a successful Edge 840 build.
5. Report all compiler warnings and errors, even if the build succeeds.
6. Do not claim simulator validation unless a human actually performed it in the graphical environment.

## Sandbox and build tools

Garmin SDKs and device definitions are mounted read-only. The real developer
key is unavailable in the development environment and must never be requested,
copied, generated, logged, or committed. Use the repository wrappers instead
of invoking the underlying Garmin tools directly.

`tools/garmin` targets Edge 840 by default and supports Edge 540, 550, 840,
850, 1040, and 1050:

```text
./tools/garmin doctor
./tools/garmin build
./tools/garmin matrix
./tools/garmin clean
```

build performs environment checks, creates a temporary simulator-only key
outside the repository, and writes bin/app.prg. matrix builds every
supported device and writes per-device programs under bin/. Do not invoke
monkeyc directly unless diagnosing the wrapper. Do not hard-code an SDK
version or modify mounted SDK or device files.

Production and beta packaging use only the isolated trusted-host workflow:

```text
./tools/host-release prepare
./tools/host-release beta
```

Private-beta packaging uses the wrapper's dedicated Aerobic Guard beta UUID.
Production export is blocked while `VERSION` is a prerelease:

```text
./tools/host-release production
```

The trusted wrapper contains distinct Aerobic Guard production and beta UUIDs.
Never reuse another application's UUIDs, run the host-release wrapper from
Codex, or expose the real developer key.

./tools/simulator is only for a human using the graphical VS Code Docker
container. It rebuilds the app, starts the Connect IQ simulator, and loads the
selected device program. Edge 840 is the default; the other supported devices
can be selected with --540, --550, --850, --1040, or --1050. Do not
invoke it from Codex because the Codex sandbox does not have access to the
required simulator and GUI toolchain. Codex must use the repository doctor,
build, and check wrappers for command-line validation.

Run the full automated gate after source, resource, or tool changes:

```text
./tools/check
```

It checks Python syntax, shell syntax, Garmin-state isolation, resource and
manifest XML, Git whitespace errors, and the Edge 840 Garmin build. Confirm
that bin/app.prg was produced and report every compiler warning or error.
Add project-specific validators and tests to this gate as the application
develops. The graphical Connect IQ simulator remains a manual step.

## FIT tools and private recordings

Use tools/fit_dump.py for CRC-checked generic FIT decoding and export:

```text
./tools/fit_dump.py path/to/activity.fit
./tools/fit_dump.py path/to/activity.fit --message record --json
./tools/fit_dump.py path/to/activity.fit --output-dir /tmp/fit-export
```

A CRC or decoding failure is an analysis failure and must be reported. If the
new application defines its own FIT developer fields, create a project-specific
validator and add it to tools/check; do not reuse another application's FIT
contract or validator.

Ride FIT files and related notes belong under the ignored fit-files/
directory. They may contain location, activity, and personal sensor data.
Never commit, publish, or copy them outside the repository.
