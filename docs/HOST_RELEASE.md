# Host-only release signing

This workflow must run only on the trusted host, never in Codex or the normal
development container. It uses the distinct production and beta UUIDs recorded
in `tools/host-release` and a read-only developer key:

```text
./tools/host-release prepare
./tools/host-release beta
./tools/host-release production
```

The wrapper refuses a dirty tree and symlinked compiler inputs, stages only
source/resources/manifest/Jungle data, and runs a network-disabled, read-only,
capability-dropped one-shot container. It records compiler output, commit and
image metadata, and a SHA-256 checksum. The beta package filename includes
`-beta`. `production` is unavailable until the repository version is stable.

Run `prepare` from the exact clean release commit, then run only the export mode
needed for that store record. For the public release, review the generated
`aerobic-guard-<version>.iq.compiler.txt` and
`aerobic-guard-<version>.iq.build.txt`, and verify the package against its
`.sha256` file before upload. The production package retains the UUID in
`manifest.xml`; the beta package substitutes only the dedicated beta UUID in
the isolated staged copy.
