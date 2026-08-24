# Releasing

Release candidates must pass `./tools/check-portable`, `./tools/garmin doctor`,
`./tools/check`, and `./tools/garmin matrix`. Confirm `bin/app.prg`,
`bin/tests.prg`, and all six matrix PRGs. Compiler warnings are failures.

Complete the unchecked simulator and physical-device items in
`RELEASE_PROGRESS.md`. On a trusted signing host, use `tools/host-release` as
documented in `HOST_RELEASE.md`. Never place the developer key in this repo.
Production export is blocked while `VERSION` contains a prerelease suffix.
