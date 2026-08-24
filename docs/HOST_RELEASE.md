# Host-only release signing

This workflow must run only on the trusted host, never in Codex or the normal
development container. Supply an external beta UUID and read-only developer key:

```text
GARMIN_BETA_UUID=<new-aerobic-guard-beta-uuid> ./tools/host-release prepare
GARMIN_BETA_UUID=<new-aerobic-guard-beta-uuid> ./tools/host-release beta
```

The wrapper refuses a dirty tree and symlinked compiler inputs, stages only
source/resources/manifest/Jungle data, and runs a network-disabled, read-only,
capability-dropped one-shot container. It records compiler output, commit and
image metadata, and a SHA-256 checksum. `production` is unavailable until the
repository version is stable.
