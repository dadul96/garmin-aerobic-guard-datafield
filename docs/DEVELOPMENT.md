# Development workflow

Supported configuration entry points are the on-device menus and proportional
keypad. Edge 540/550 use wrapping Up/Down focus and Enter/Start activation;
840/850/1040/1050 use coordinate taps. Immediate top-view replacement keeps
edits visible while preserving the settings stack.

Use `./tools/check-portable` without an SDK, `./tools/check` for the Edge 840
app and test compile, and `./tools/garmin matrix` for all six release products.
Direct key-based packaging was removed from `tools/garmin`; only the trusted
host workflow in `HOST_RELEASE.md` may sign exports.

## Environments

Codex performs command-line implementation and validation in the sandbox. A
human uses the graphical VS Code Docker container for the Connect IQ simulator
and on-device settings interaction.

The mounted Garmin SDKs and device definitions are read-only. Repository
wrappers isolate Garmin state and create temporary simulator-only signing keys.
Never request, generate, copy, log, or commit a real Garmin developer key.

## Supported commands

Check the command-line environment before relying on it:

```bash
./tools/garmin doctor
```

Build the production Edge 840 data field:

```bash
./tools/garmin build
```

Compile the Run No Evil test program:

```bash
./tools/garmin test
```

Run the complete automated gate:

```bash
./tools/check
```

The production artifact is `bin/app.prg`. See [`TESTING.md`](TESTING.md) for
test execution instructions.

Do not invoke `monkeyc` directly unless diagnosing the wrapper. Do not invoke
`./tools/simulator` from Codex; it is reserved for a human in the graphical
container.

## Settings workflow

Aerobic Guard exposes an on-device settings view through
`Application.AppBase.getSettingsView()`. On an Edge device or in the simulator,
the data-field configuration is opened from the activity's data-field menu.

Settings are grouped into Power, Heart Rate, Cadence, and Fueling.
Guidance stays inactive until its enable switch and required numeric target(s)
form a valid configuration. On first active-field computation, valid Garmin
cycling Zone 2 data initializes and enables power and HR guidance. If power
zones are unavailable but cycling FTP is positive, power uses the standard
56-75% FTP Zone 2 fallback. The attempt is persisted, existing non-zero targets
are preserved, and later Garmin profile changes never overwrite settings.

Cadence and carbohydrate settings use a separate one-time initialization guard
so existing installations also receive the defaults safely: 80-95 rpm cadence
and 60 g/h carbohydrate rate. Non-zero existing values are never replaced.

Settings are intentionally available only through the on-device menu; the app
does not publish a Garmin Connect/host settings resource. Numeric settings use
the integer keypad in `SettingsMenu.mc`; it supports both coordinate-based
touch and physical Up/Down/Enter/Start buttons. Its range checks supplement
rather than replace `SettingsModel` validation.

Power and cadence require strictly ordered positive limits. When the companion
limit exists, the keypad limits a lower value to at most `upper - 1` and an
upper value to at least `lower + 1`, then rechecks the companion on save. Either
limit may be entered first from an unconfigured zero/zero state, but guidance
cannot be enabled until the pair is complete and valid. Invalid legacy values
are preserved for correction rather than silently reordered.

The Power section also contains a 1-30 second displayed-power moving-average
window. Its 1-second default preserves raw power. The filter affects the power
number and color-fill edge together.

The keypad uses a `WatchUi.BehaviorDelegate`. Garmin defines it as an
`InputDelegate` subclass, so it receives raw `onTap()` callbacks while also
providing device-independent Back handling.

The production keypad is deliberately application-specific. The
[`reusable_numeric_keypad`](../reusable_numeric_keypad/README.md) directory is
a separate, self-contained reference export for other Connect IQ projects; it
is not on Aerobic Guard's production source path.

Do not add `onSelect()` to the keypad delegate. Garmin may dispatch a touch as
Select, which would activate the focused control instead of the tapped cell.

Do not rely on `WatchUi.requestUpdate()` for keypad digit feedback. Physical
Edge data-field settings do not reliably repaint pushed views from that call.
The delegate uses `switchToView()` with `SLIDE_IMMEDIATE` to replace only the
active keypad and preserve the settings menu below it.

Garmin profile-dependent initialization runs on the first data-field
`compute()` callback. Product-only defaults run on the initial-view path. Do
not move property writes into `onStart()` or `getSettingsView()`, where they can
interfere with settings-view construction.

## Change checklist

For substantive source or resource work:

1. Preserve the product boundaries in `AGENTS.md`.
2. Update tests for changed pure logic.
3. Update relevant files under `docs/` when behavior or workflow changes.
4. Add or amend an entry in `DECISIONS.md` for a durable design decision.
5. Run `./tools/garmin build` and `./tools/check`.
6. Confirm `bin/app.prg` exists and report every compiler warning or error.
