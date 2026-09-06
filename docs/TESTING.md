# Testing

The portable gate validates logic, scripts, XML/JSON, release metadata, exact
six-product capabilities, assets, state isolation, and whitespace. The normal
gate additionally compiles warning-free Edge 840 app and test programs. The
release matrix must leave `bin/app-edge540.prg`, `app-edge550.prg`,
`app-edge840.prg`, `app-edge850.prg`, `app-edge1040.prg`, and
`app-edge1050.prg`.

`./tools/simulator --tests --840` builds and loads the test program in the
human graphical environment. Device selectors cover all six products. Passing
command-line compilation is not simulator, physical-device, upload, or
store-review evidence. `RELEASE_PROGRESS.md` records those separately.

The portable regression suite also verifies that custom-rendered and mutable
menu text resolves resource identifiers before use, including unavailable
values rendered before the first activity sample.

Aerobic Guard has two complementary test layers:

1. Repository-side Python tests execute without the graphical simulator.
2. Garmin Run No Evil tests exercise the Monkey C production classes in the
   Connect IQ simulator.

Neither test layer requires simulated activity or sensor data. Tests provide
their own power, heart-rate, cadence, and elapsed-time values.

## Full automated gate

Run this after source, resource, documentation-related tooling, or wrapper
changes:

```bash
./tools/check
```

The gate executes the Python reference vectors, syntax and XML validation,
Garmin-state isolation checks, the production Edge 840 build, and compilation
of the Monkey C unit-test program. It confirms both of these artifacts exist:

```text
bin/app.prg
bin/tests.prg
```

Compiling `bin/tests.prg` proves that the Monkey C test suite is valid, but it
does not execute the tests. Garmin's Run No Evil framework executes only in the
graphical Connect IQ simulator.

## Build the Monkey C test program

```bash
./tools/garmin test
```

This produces `bin/tests.prg` using a temporary simulator-only key. Do not use
or request a real Garmin developer key for tests.

## Execute all Monkey C tests

These commands must be run by a human in the graphical VS Code Docker
container, not from Codex.

Start the simulator:

```bash
connectiq
```

With the simulator still running, open another terminal in the repository and
run:

```bash
monkeydo bin/tests.prg edge840 -t
```

On Linux the test flag is `-t`. `/t` is a Windows form and will launch the
program without running the tests.

Test results are printed in the terminal that ran `monkeydo`, not on the
simulated Edge screen. A successful run ends with output similar to:

```text
RESULTS
...
PASSED (failures=0, errors=0)
```

A test returning `false` is reported as a failure. An exception or crash is
reported as an error.

To run one test, append its function name:

```bash
monkeydo bin/tests.prg edge840 -t testPowerMovingAverage
```

The current Monkey C tests cover:

- equal live-bar geometry and redistribution for every guidance visibility
  combination;
- the tighter power/cadence scale and visually clamped fill-edge contract;
- equal footer redistribution with fueling enabled/disabled, Garmin metric or
  statute speed units, and a visible under-range stub at zero;
- carbohydrate block calculation and rounding;
- numeric keypad editing, maximum-derived length limiting, and range validation;
- strict power/cadence ordering, companion-derived keypad bounds, and blocking
  guidance enablement until both limits form a valid pair;
- numeric keypad touch-region mapping and button-focus wraparound;
- the keypad delegate and tap-handler contract, plus the visible-row and
  live-settings refresh hooks after edits and immediate keypad repaint path;
- isolation of one-time default writes from settings-view startup;
- absence of the Garmin Connect/host settings surface while property defaults
  remain available to the on-device settings view;
- safe carbohydrate numeric formatting with unit characters outside numeric
  format patterns;
- validation of only the consumed power-zone thresholds and presence of the
  latest corrective-import migration guard;
- the 56-75% cycling-FTP fallback and its whole-watt rounding.

## Repository-side tests

The executable Python reference vectors can be run separately with:

```bash
python3 tools/test_logic.py
```

These tests provide fast command-line feedback. When changing a calculation,
update both the production Monkey C tests and the Python reference vectors so
that they describe the same intended behavior.

## Manual validation

The automated tests do not establish screen readability, correct integration
with live sensors, or behavior during a real ride. Record simulator and device
observations in the relevant change report. Never claim simulator or device
validation unless a human performed it.

### Recorded Edge 840 observations — 2026-08-15

- Human testing confirmed the power initialization fallback in both the Edge
  840 simulator and on a physical Edge 840. In the simulator,
  `getPowerZones()` returned `null` while Garmin supplied cycling FTP; the
  56-75% FTP fallback initialized and enabled the expected power target.
- Human physical-device testing found that keypad input, length limits, range
  validation, and saving worked, but `WatchUi.requestUpdate()` left the visible
  number stale while typing. Simulator repainting was merely delayed.
- Human physical-device retesting confirmed that immediate top-view replacement
  fixes live digit repainting on Edge 840. Back/OK navigation, validation, and
  saving continue to work correctly with the settings menu preserved beneath
  the keypad.

Button-only keypad navigation has automated model/build coverage but still
requires human verification on physical hardware. Confirm initial OK focus,
Up/Down wraparound, Enter/Start activation, visible focus repainting, and Back
cancellation without saving.

### Riding-dashboard readability review

After dashboard changes, inspect the all-enabled page and at least one reduced
configuration on a physical Edge 840. Include steady, persisted warning,
missing-sensor, missing-HR-zone, and off-scale states. Confirm at a normal
riding glance that power is immediately readable, HR and its
ceiling are distinct, warning meaning survives without color, target posts are
distinct from color-fill edges, the larger three-column footer does not overlap,
the speed unit remains legible, zero power/cadence has a visible amber stub,
fueling-off expands speed/time equally, and guidance toggles remove bars while
equally resizing the remainder. Repeat in bright
outdoor light. This is a human device check; a build or simulator run does not
establish physical readability.
