# Aerobic Guard user guide

Aerobic Guard is a full-screen cycling data field for long aerobic rides. It
keeps power, a heart-rate ceiling, cadence guidance, cumulative carbohydrate
target, speed, and elapsed activity time on one page. It does not start or save
an activity, execute workouts, send alerts, or record extra FIT data.

## Compatibility and prerequisites

Aerobic Guard supports Edge 540 / 540 Solar, Edge 550, Edge 840 / 840 Solar,
Edge 850, Edge 1040 / 1040 Solar, and Edge 1050 with Connect IQ 6.0.0 or newer.

Pair the sensors needed for the values you want to see. Power requires a power
source such as a paired power meter or smart trainer, and heart rate requires a
heart-rate source. Cadence and speed use the values Garmin makes available to
the activity. A missing value is shown as `--`; Aerobic Guard never substitutes
zero or an older reading for a missing sensor sample.

If you want the first-start import, configure your cycling power and heart-rate
zones in Garmin before first opening the data field. The import runs only once.

## Install and add the field

1. Install Aerobic Guard from the Connect IQ Store and sync your Edge.
2. On the Edge, open **Activity Profiles**, then choose the cycling profile you
   intend to use.
3. Open **Data Screens** and add or edit a data screen.
4. Choose the one-field, full-screen layout and assign **Aerobic Guard** to it.
5. Make sure the screen is enabled for the profile.
6. Open that data page once so first-start initialization can finish before you
   review the settings.

Garmin changes some menu labels between Edge models and firmware versions. The
essential requirement is a data screen containing Aerobic Guard as its only
field. Any smaller layout shows `FULL SCREEN REQUIRED`.

## Review settings before the first ride

Open Aerobic Guard's data-field settings from the activity profile on the Edge.
Settings are intentionally on-device only; there is no settings page in the
Connect IQ phone app, Garmin Connect, or Garmin Express.

On first start, Aerobic Guard attempts to initialize:

- power from Garmin cycling Power Zone 2, or from 56–75% of a positive cycling
  FTP when usable zone thresholds are unavailable;
- the HR ceiling from Garmin's maximum cycling Zone 2 threshold;
- cadence to 80–95 rpm; and
- carbohydrate rate to 60 g/h.

The imported power and HR values are starting points, not ongoing
synchronization. The attempt is recorded even when Garmin supplies no usable
zones, and Aerobic Guard never automatically changes the targets later. Review
every value for your own plan. The cadence and carbohydrate values are product
defaults, not personalized prescriptions.

The settings are:

- **Power:** show guidance, lower and upper limit, and displayed-power average
  from 1 to 30 seconds. `1s` is current one-second power.
- **Heart Rate:** show guidance and a ceiling. There is no lower HR target.
- **Cadence:** show guidance and lower and upper limits.
- **Fueling:** show cumulative carbohydrate target and set grams per hour.

Disabling power, HR, or cadence removes that bar and expands the remaining
bars. Disabling fueling removes the carbohydrate footer value and expands
speed and time.

## Read the riding screen

Each enabled primary bar combines its live number and range position:

- green means within the configured power/cadence range or at/below the HR
  ceiling;
- amber means power or cadence is below its configured range;
- red means power is above its range or HR is above its ceiling;
- the heavy vertical post or pair of posts marks the configured boundary;
- the color-fill edge marks the current value;
- an outward arrow means the current value is beyond the visual scale; and
- the small outlined downward triangle marks Garmin's activity average when
  Garmin supplies one.

Color is redundant: posts, edges, arrows, and numbers carry the same essential
information. Numeric values remain the real measurements even when a marker is
visually clamped to an endpoint.

The HR bar uses Garmin's configured cycling HR-zone minimum and maximum as its
drawing range. If Garmin does not provide a valid range, Aerobic Guard still
shows numeric HR and the configured ceiling with a reduced visualization.

The footer shows:

- **carbohydrate by now**, updated after each completed 10-minute block from
  elapsed activity time;
- current speed in Garmin's configured `km/h` or `mph`; and
- elapsed activity time.

The carbohydrate number is a cumulative planning target. It is not a reminder,
food log, serving recommendation, or statement of what you actually consumed.

## Troubleshooting

- **`FULL SCREEN REQUIRED`:** change the data screen to a one-field layout.
- **A value shows `--`:** confirm the relevant sensor is paired, connected, and
  providing that value to the Garmin activity.
- **Power or HR did not initialize:** the one-time lookup did not receive valid
  Garmin cycling data. Enter the target manually in the on-device settings.
- **A guidance bar is absent:** enable that section and enter a valid target.
  Power and cadence require positive limits with lower strictly below upper;
  HR requires a positive ceiling.
- **Targets no longer match Garmin zones:** this is expected after Garmin zone
  changes. Aerobic Guard never recalculates targets after its one-time import;
  update them manually.
- **The carbohydrate value remains zero:** it advances only at 10, 20, 30, and
  subsequent completed 10-minute points of elapsed activity time.

For bugs or support, open a [GitHub issue](https://github.com/dadul96/garmin-aerobic-guard-datafield/issues).
Please include the Edge model, firmware version, app version, and steps to
reproduce. Do not attach FIT files publicly; they may contain location and
personal sensor data.
