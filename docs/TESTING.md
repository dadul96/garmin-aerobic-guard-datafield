# Testing

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

Coaching-state assertions use `String.equals()` because Monkey C's `==`
operator compares object identity rather than string content. Failed coaching
tests log both the expected state and the actual state before returning.

To run one test, append its function name:

```bash
monkeydo bin/tests.prg edge840 -t testHeartRateVeto
```

The current Monkey C tests cover:

- power-warning persistence;
- coaching priority;
- HR veto of low-power coaching;
- adaptive dashboard bounds and height redistribution for enabled and disabled
  riding cards;
- the tighter power/cadence gauge scale and visually clamped marker contract;
- drift readiness and the drift formula;
- drift warning behavior below, at, and above the configured threshold;
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
- safe numeric formatting for the enabled-by-default carbohydrate display;
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
configuration on a physical Edge 840. Confirm that the coaching state and live
power/HR values can be read at a normal riding glance, colored backgrounds
retain sunlight contrast, off-scale arrows are distinguishable, and disabling
a feature expands the remaining cards. This is a human device check; a build
or simulator run does not establish physical readability.
