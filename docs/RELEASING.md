# Releasing

This is the release-owner checklist for the public source repository and the
Connect IQ Store. `RELEASE_PROGRESS.md` records the evidence for the current
release. Garmin's developer dashboard and the trusted signing host are human-
only environments.

## 1. Freeze and validate the release candidate

1. Confirm `VERSION` is a stable semantic version with no prerelease suffix and
   that `CHANGELOG.md` has the matching heading.
2. Confirm the manifest contains only the intended production UUID, supported
   products, API floor, and permissions.
3. From a clean release commit, run:

   ```bash
   ./tools/check-portable
   ./tools/garmin doctor
   ./tools/check
   ./tools/garmin matrix
   ```

4. Confirm `bin/app.prg`, `bin/tests.prg`, and all six device programs exist.
   Every compiler warning or error is a release failure.
5. Complete the applicable simulator, physical-device, FIT, and beta evidence
   in `RELEASE_PROGRESS.md`. Compilation is not a substitute for those checks.
6. Review the full diff from the preceding release and confirm there are no
   secrets, developer keys, private FIT files, exported packages, personal
   notes, or unrelated files in Git history.

## 2. Publish the source repository prerequisites

The store listing links to files on the repository's `main` branch. Before
submitting the production listing:

1. Confirm the original developer key has at least one encrypted backup outside
   the signing host. Garmin does not retain a recoverable copy, and future app
   updates must be signed by the same key.
2. In the developer dashboard, confirm the account is in good standing, the
   public **Contact Developer** email is appropriate, and the intended regional
   availability is selectable. Aerobic Guard is free and requests no payment,
   tip, or donation, so declare it non-monetized/non-trader as applicable.
3. Confirm the logo, generated hero source, screenshots, text, and code are
   yours to publish and contain no third-party marks or private ride data.
4. Push the final release commit.
5. Change the GitHub repository visibility to public.
6. While signed out of GitHub, verify that `README.md`, `PRIVACY.md`,
   `docs/USER_GUIDE.md`, and the issue tracker links all open.
7. Set the GitHub repository description and topics, confirm Issues are
   enabled, and keep the default branch set to `main`.

Do not commit or attach the developer key, ignored FIT recordings, `bin/`, or a
signed `.iq` package. The Connect IQ Store is the application distribution
channel.

## 3. Create the production package

Follow `HOST_RELEASE.md` on the trusted signing host. In summary:

```text
./tools/host-release prepare
./tools/host-release production
```

Review the generated compiler transcript and verify the SHA-256 checksum before
uploading. Record the release commit, package checksum, compiler version, and
container image in `RELEASE_PROGRESS.md`. Do not run this workflow from Codex
or the normal development container.

## 4. Create the production Connect IQ listing

The private beta and production app have different UUIDs and therefore
different store records. In Garmin's developer dashboard, upload the production
`.iq` as a new app with **Beta App unchecked**. Do not promote or overwrite the
alternate-UUID beta record.

After Garmin validates the package:

1. Set the public name to **Aerobic Guard**, language to English, and price to
   free/non-monetized.
2. Use `store/english.md` as the English description source.
3. Upload `assets/store/icon-500.png`, `assets/store/icon-128.png`,
   `assets/store/hero-1440x720.png`, and the five files under
   `assets/screenshots/` in their numbered order. The 128-pixel icon is the
   optional on-device Store icon.
4. Supply the public privacy, support, and user-guide links from the store text.
5. If Garmin asks why User Profile permission is required, explain that it is
   used for the one-time cycling power-zone/FTP and HR-ceiling initialization
   and for the HR graph's cycling-zone range.
6. Verify the preview says **Data Field**, lists exactly the supported Edge
   products, describes on-device settings, and does not imply workout control,
   medical advice, food logging, notifications, networking, or FIT recording.
7. Open every listing link while signed out, then submit for review.

The already accepted beta is strong evidence that the package structure and
device compatibility are valid, but production still receives its own Garmin
review. Watch the developer-account email for approval or a specific rejection.

## 5. Finish after approval

1. Verify the public listing while signed out and install it through the normal
   public Store path on a supported Edge.
2. Confirm a fresh install, one-field placement, first-start defaults, settings,
   and a short recorded activity.
3. Add the final Store URL to `README.md` once its public identifier is known.
4. Create and push the annotated Git tag `v1.0.0`, and create a GitHub release
   from that tag using the matching changelog entry. Do not attach the `.iq`.
5. Mark only the completed evidence in `RELEASE_PROGRESS.md` and monitor Garmin
   crash reports and GitHub issues after launch.

## Garmin references

- [Publishing to the Connect IQ Store](https://developer.garmin.com/connect-iq/core-topics/publishing-to-the-store/)
- [Beta apps](https://developer.garmin.com/connect-iq/core-topics/beta-apps/)
- [App review guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/)
- [Connect IQ brand and Store assets](https://developer.garmin.com/brand-guidelines/connect-iq/)
- [Connect IQ developer agreement](https://developer.garmin.com/connect-iq/sdk/)
