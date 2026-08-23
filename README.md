# Aerobic Guard

Aerobic Guard is a calm, full-screen Garmin Connect IQ data field for long
aerobic and endurance cycling rides. It keeps the information needed to stay
inside a sustainable envelope on one glanceable page without trying to replace
Garmin's structured-workout experience.

The project currently targets the **Garmin Edge 840** and requires **Connect IQ
API 6.0.0 or newer**. It is source-only and pre-release: there is no published
Connect IQ Store installation yet.

## What it shows

- Raw current power with a configurable target range
- Current heart rate with a ceiling and Garmin cycling-zone drawing range
- Cadence with an advisory target range
- Cumulative carbohydrate target at completed ten-minute blocks
- Speed and elapsed activity time

Aerobic Guard handles unavailable sensor values explicitly and never invents
measurements or physiological targets. Live bar position, target posts, and
color show each enabled metric's current relationship to its configured limits.

## Initial settings

On the first data-field start, the app can initialize power and heart-rate
guidance from Garmin's configured cycling zones. If power-zone thresholds are
unavailable and cycling FTP is positive, power can use Garmin's standard
56–75% FTP Zone 2 range. This import is attempted only once and never
overwrites non-zero rider settings.

Cadence starts at 80–95 rpm and the carbohydrate target starts at 60 g/h.
These one-time product defaults remain editable. Settings are managed on the
Edge through the data field's own settings menus.

## Privacy and scope

The app works entirely on the device. It has no networking, accounts, cloud
synchronization, navigation, or location handling. It does not use
`Toybox.FitContributor` and does not write custom FIT developer fields.

The repository includes an optional FIT inspection utility for private local
testing. Ride files may contain location and personal sensor data, belong only
under the ignored `fit-files/` directory, and must never be committed or
published.

## Build and test

Garmin SDKs and device definitions must already be available in a supported
local development environment. Repository wrappers create temporary
simulator-only keys; a real Garmin developer key is neither needed nor accepted
for normal builds and tests.

```bash
./tools/garmin doctor
./tools/garmin build
./tools/check
```

A successful production build creates the ignored artifact `bin/app.prg`.
`./tools/check` runs repository-side tests, validates scripts and XML, builds
the Edge 840 app, and compiles the Monkey C Run No Evil test program.

Graphical simulator tests and physical-device checks remain human steps. A
successful command-line build does not establish sunlight readability, live
sensor integration, or on-road behavior. See
[`docs/TESTING.md`](docs/TESTING.md) for the current validation record and
manual test instructions.

## Documentation

- [`AGENTS.md`](AGENTS.md) — product and engineering source of truth
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — modules and runtime flow
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — supported development workflow
- [`docs/TESTING.md`](docs/TESTING.md) — automated and human validation
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — durable design decisions
- [`reusable_numeric_keypad/`](reusable_numeric_keypad/) — reusable keypad reference

## Contributing

Keep changes within the Edge 840 endurance-data-field scope described in
`AGENTS.md`. Update tests and durable documentation with behavior changes, use
the repository wrappers rather than invoking Garmin tools directly, and run
`./tools/check` before submitting a change.

## License

Aerobic Guard is available under the [MIT License](LICENSE).
