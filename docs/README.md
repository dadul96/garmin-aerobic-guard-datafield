# Aerobic Guard documentation

This directory contains the durable project documentation that complements
the product contract in [`AGENTS.md`](../AGENTS.md).

## Documents

- [`ARCHITECTURE.md`](ARCHITECTURE.md) describes the source modules, runtime
  data flow, and important implementation boundaries.
- [`DEVELOPMENT.md`](DEVELOPMENT.md) explains the supported build and
  validation workflow in the repository and graphical development containers.
- [`TESTING.md`](TESTING.md) explains the automated checks, Monkey C unit tests,
  and the manual commands used to execute Run No Evil tests in the simulator.
- [`DECISIONS.md`](DECISIONS.md) records durable product and engineering
  decisions, including their rationale and consequences.
- [`RELEASING.md`](RELEASING.md) defines the release gates.
- [`HOST_RELEASE.md`](HOST_RELEASE.md) documents isolated host-only signing.
- [`RELEASE_PROGRESS.md`](RELEASE_PROGRESS.md) records only completed evidence.

`AGENTS.md` remains the product and engineering source of truth. If a document
conflicts with it, follow `AGENTS.md` and correct the stale document.
