# Host-only release signing

This workflow must run only on the trusted host, never in Codex or the normal
development container. It uses the distinct production and beta UUIDs recorded
in `tools/host-release` and a read-only developer key:

```text
./tools/host-release prepare
./tools/host-release beta
```

The wrapper refuses a dirty tree and symlinked compiler inputs, stages only
source/resources/manifest/Jungle data, and runs a network-disabled, read-only,
capability-dropped one-shot container. It records compiler output, commit and
image metadata, and a SHA-256 checksum. The beta package filename includes
`-beta`. `production` is unavailable until the repository version is stable.
