# Design decisions

This is the durable decision log for Aerobic Guard. Add a dated entry when a
product or engineering choice constrains future work, resolves a meaningful
trade-off, or deliberately rejects an alternative. Do not use it as a task log
or duplicate routine implementation details.

Each entry should state the decision, rationale, and consequences. Amend an
existing entry when clarifying it. Add a new entry that supersedes the old one
when reversing a decision; do not erase the history.

## 2026-08-15 — Edge 840 is the only declared MVP target

**Decision:** The manifest declares only Edge 840 support with Connect IQ API
6.0.0 or newer.

**Rationale:** The first product pass is designed and validated around one
known screen, memory limit, and interaction model.

**Consequences:** Build wrappers may know about other Edge devices, but product
support must not be broadened without an explicit product decision and device
validation.

## 2026-08-15 — Use a light, high-contrast dashboard

**Decision:** The riding dashboard uses a white background, black primary
content, and dark-gray secondary labels and guides.

**Rationale:** A human simulator review preferred the light presentation, and
it aligns with the goal of sunlight readability.

**Consequences:** New visual elements must remain legible without relying on
color. Theme configurability is not part of the MVP settings surface.

## 2026-08-15 — Guidance starts unconfigured

**Decision:** Personalized power, HR, cadence, and fueling targets default to
disabled or zero/unconfigured. Only technical persistence defaults are supplied
(5 seconds power, 20 seconds HR, and 10 seconds cadence).

**Rationale:** The application cannot safely infer personalized physiological
or training targets.

**Consequences:** Live metrics remain visible, while target gauges and coaching
remain inactive until valid values are configured.

This decision is superseded for power and HR by the one-time cycling-zone
initialization decision below, and for cadence and fueling by their separate
one-time product-default decision.

## 2026-08-15 — Initialize power and HR once from cycling Zone 2

**Decision:** On the first application start, initialize the power range from
one watt above Garmin cycling Zone 1 maximum through cycling Zone 2 maximum,
and initialize the HR ceiling from Garmin cycling Zone 2 maximum. Valid imports
enable their corresponding guidance. Preserve existing non-zero targets, mark
the attempt complete even when Garmin returns `null`, malformed data, or an
error, and never automatically import or recalculate these targets again.

**Rationale:** Garmin's configured cycling zones provide a useful personalized
starting point while a permanent one-time guard ensures subsequent rider edits
remain authoritative.

**Consequences:** Power and HR normally start ready to use when Garmin supplies
valid thresholds. A failed first attempt leaves zero/unconfigured values until
the rider enters them manually; later Garmin zone changes have no effect.

## 2026-08-15 — Provide one-time cadence and carbohydrate defaults

**Decision:** On first initialization, set cadence guidance to 80-95 rpm and
the carbohydrate display rate to 60 g/h, enabling both features. Use a separate
persistent guard from Garmin-zone initialization, preserve existing non-zero
values, and never reapply the defaults automatically.

**Rationale:** These conservative endurance-oriented starting values make the
MVP useful without requiring every setting to be entered manually. They are
product defaults, not individualized physiological or fueling prescriptions.

**Consequences:** New and existing development installations receive usable
cadence and carbohydrate settings once. Rider edits remain authoritative, and
the application continues to provide no fueling notifications or serving
recommendations.

## 2026-08-15 — Correct the zero-watt power-zone import once

**Decision:** Accept zero as Garmin's minimum Power Zone 1 threshold. Existing
installations receive one versioned corrective power-only import attempt when
both stored power limits remain zero. Non-zero targets are never overwritten.

**Rationale:** The original shared HR/power validator required a positive first
threshold. Valid Garmin power-zone arrays can start at zero watts, so the app
rejected them and then persisted completion of the failed import.

**Consequences:** Fresh installations import normally. Affected installations
can recover automatically once without clearing all app settings, while the
separate migration guard preserves the original no-recalculation contract.

This decision was refined after device testing showed that accepting a
zero-watt first element was insufficient. Garmin does not document the first
power-array element's semantics. Power import now validates only the Zone 1 and
Zone 2 maximum thresholds it actually consumes, and a second versioned
corrective attempt covers installations that consumed the first migration.

## 2026-08-15 — Fall back to Garmin cycling FTP for power Zone 2

**Decision:** Prefer Garmin's configured cycling power-zone thresholds. When
`getPowerZones(Activity.SPORT_CYCLING)` returns no valid thresholds but Garmin
provides a positive cycling FTP, initialize the power target to 56-75% FTP.
Round the lower boundary upward and the upper boundary downward to whole watts.
A versioned one-time migration applies this fallback to existing installations
only while both stored power targets remain zero.

**Rationale:** Simulator diagnostics showed that Garmin exposes cycling FTP
while returning `null` for both cycling and generic power-zone arrays. Garmin
publishes 56-75% FTP as the standard endurance Zone 2 range, so this gives a
Garmin-derived personalized starting target without requiring inaccessible
zone-boundary data.

**Consequences:** Explicit Garmin zone thresholds remain authoritative when
available. The FTP fallback cannot reproduce manually customized zone
boundaries, but it never overwrites non-zero Aerobic Guard targets and never
recalculates them after its one-time initialization.

## 2026-08-15 — Provide native on-device settings

**Decision:** The data field exposes `AppBase.getSettingsView()` with five
focused sections: Power, Heart Rate, Cadence, Fueling, and Drift. Toggles and
numeric pickers write the same properties used by XML/mobile settings.

**Rationale:** Data fields cannot accept configuration input from the riding
view, and a human simulator review showed that XML settings alone did not make
the targets reachable through the tested activity-menu workflow.

**Consequences:** Property keys and validation semantics must stay aligned
between `SettingsMenu.mc`, `SettingsModel.mc`, and resource XML.

## 2026-08-15 — Bound drift memory with minute buckets

**Decision:** Baseline efficiency uses aggregate sums and counts; the recent
ten-minute window uses ten fixed one-minute buckets.

**Rationale:** Retaining per-second samples for an entire ride would grow
without bound, while minute buckets preserve the required window averages with
small fixed memory.

**Consequences:** The recent window advances at minute boundaries. Drift is not
meaningful until 40 minutes, at least 720 valid baseline samples, and at least
480 valid recent samples.

## 2026-08-15 — Use a touch keypad for numeric settings

**Decision:** On-device integer settings use a custom 3×4 touch keypad with
digits, backspace, OK, hardware-back cancellation, and inclusive range checks.
This supersedes the numeric-picker portion of the earlier on-device-settings
decision; the five-section menu structure and shared properties remain.

**Rationale:** Human simulator testing found the scrolling picker painful for
entering cycling targets, while the keypad interaction worked well on Edge 840.
Garmin's deprecated native `NumberPicker` is not supported on Edge 840, and
`TextPicker` provides a device-specific general text keyboard rather than a
numeric-only contract.

**Consequences:** The settings flow now assumes the declared Edge 840 touch
interaction model. Range validation remains duplicated defensively in the
  settings model. A generic reference copy lives under
  `reusable_numeric_keypad/`, outside the application source path, for
  deliberate adaptation in other projects.

## 2026-08-15 — Use two complementary unit-test layers

**Decision:** Keep fast executable Python reference vectors and compile Garmin
Run No Evil tests against the Monkey C production classes.

**Rationale:** Python tests run in the command-line gate, while Monkey C tests
provide direct production-language coverage but require the graphical simulator
for execution.

**Consequences:** `./tools/check` runs the Python tests and compiles
`bin/tests.prg`. A human runs the Monkey C tests with
`monkeydo bin/tests.prg edge840 -t` and reads results in that terminal.

## 2026-08-15 — Force immediate keypad repaint on Edge hardware

**Decision:** After a keypad digit, backspace, or validation error, replace the
active keypad with itself using `WatchUi.switchToView()` and
`SLIDE_IMMEDIATE`. Keep the same view model and delegate so only the top stack
entry changes.

**Rationale:** Simulator and physical Edge testing showed that
`WatchUi.requestUpdate()` is delayed in the simulator and does not reliably
repaint a pushed data-field settings view on Edge 840 hardware. Input and saving
were correct, but the displayed number remained stale until OK.

**Consequences:** Keypad feedback is immediate and the settings section remains
underneath it for Back/OK navigation. Future keypad changes must preserve the
top-view-only replacement behavior unless physical-device testing establishes
a better supported refresh mechanism.

## 2026-08-15 — Scale power and cadence gauges around their targets

**Decision:** Draw power and cadence gauges from half the configured lower
limit through one-and-a-half times the configured upper limit. Clamp markers
outside that drawing range without changing the displayed numeric measurement.

**Rationale:** Human simulator review found that centering the useful drawing
range around the configured endurance target made the target band and live
position easier to judge than scales beginning at zero.

**Consequences:** Gauge endpoints vary with the rider's configured targets.
For example, a 170-200 W target draws across 85-300 W, and the default 80-95
rpm cadence target draws across 40-142.5 rpm. Coaching thresholds themselves
are unchanged.

## 2026-08-15 — Do not simulate pre-ride edge cases before the first ride test

**Decision:** Defer the planned simulator exercise for pause/resume, missing
sensors, coasting, HR veto, and persistence transitions in favor of an initial
real-ride test.

**Rationale:** The user chose to prioritize settings availability and unit
tests, followed by a real ride.

**Consequences:** Automated logic coverage exists, but integration behavior for
those cases remains to be observed on the device and should be revisited if the
ride exposes issues.

## 2026-08-17 — Support button-only integer settings entry

**Decision:** Retain the custom non-negative integer keypad while adding a
visible, wrapping focus navigated by physical Up/Down buttons and activated by
Enter/Start. OK is initially focused. Touch remains coordinate-driven in
`onTap()` and the delegate deliberately has no `onSelect()` implementation.

**Rationale:** Settings require only whole numbers, and the declared device
must remain operable when touch is unavailable or undesirable. Separating raw
key handling from touch avoids Garmin dispatching a tap to the focused OK
control instead of the tapped digit.

**Consequences:** Every numeric setting can be accepted unchanged immediately
or edited with buttons alone. Focus changes use the same immediate top-view
replacement as digit edits. Touch behavior and the underlying settings stack
remain unchanged; physical-device verification is still a human responsibility.

## 2026-08-17 — Enable drift display by default

**Decision:** New installations start with the drift display enabled.

**Rationale:** Aerobic drift is a core endurance context metric and should be
visible without requiring an initial settings change.

**Consequences:** The resource default changes to enabled. Existing persisted
user choices are not migrated or overwritten, and the drift readiness rules
remain unchanged.

## 2026-08-17 — Use an adaptive large-type riding dashboard

**Decision:** Remove the application-name row and render the riding view as a
large colored coaching banner followed by weighted cards. Power, HR, and
cadence settings control both guidance and card visibility; drift and
carbohydrate cards follow their existing display settings. Visible guidance
cards receive twice the height of context and footer cards. Speed and elapsed
time remain visible. Use short text labels rather than custom or Unicode icons.

This supersedes the 2026-08-15 gauge scale decision: power and cadence gauges
now draw from `lower × 0.8` through `upper × 1.2`.

**Rationale:** The complete initial dashboard was legible in a simulator but
too small to use during a real ride. A tighter gauge approximately doubles the
visible target-band width, while removing disabled cards makes their space
available to information the rider actually uses. Stable abbreviations avoid
device-font and asset ambiguity.

**Consequences:** The dashboard remains light and high contrast, refining the
earlier light-dashboard decision with colored coaching and warning cards.
Colors reinforce text and marker shape rather than replacing them. Card warning
backgrounds use persisted coaching states to prevent raw one-second values from
causing large-area flicker. Off-scale markers are clamped with a directional
endpoint indicator while numeric values remain real.

Neutral cards use a white background with one-pixel dark separators. The green
accent is slightly darker than Garmin's standard bright green and the target
band has a one-pixel black surround so it stays distinct against white in
sunlight.

The HR ceiling likewise uses a one-pixel black surround. Its center is red on
white cards and switches to white on a red HR-warning card. Current-value
markers always use the same black center, white halo, and black outer edge. The
white halo keeps the dark moving line distinct on red and yellow warning cards.

Red consistently means reduce effort: persisted HR-high and power-high
conditions color their respective cards independently, so both remain red when
they occur together even though the header prioritizes HR. Yellow remains an
advisory adjustment. HR-high suppresses yellow power-low and cadence cards so
the display never encourages a lower-priority action during an HR alert.

## 2026-08-17 — Keep settings on-device and enforce ordered targets

**Decision:** Remove the Garmin Connect/host settings resource. The custom
Edge settings view is the only supported configuration surface. Power and
cadence reject completed target pairs unless both bounds are positive and the
lower bound is strictly below the upper bound. This supersedes the shared
XML/mobile settings portion of the 2026-08-15 on-device-settings decision.

**Rationale:** Connect IQ resource settings can bound individual numbers but
cannot express a relationship between two properties. The custom keypad can
show companion-derived limits and reject the invalid edit without guessing at
the rider's intent.

**Consequences:** Existing property keys and stored values remain compatible.
Either bound may be entered first while the other is zero, but guidance stays
off until the pair is complete. Invalid legacy values are shown for correction
and are never automatically sorted or overwritten. Runtime validation remains
the final safety boundary.

## 2026-08-17 — Keep drift warnings contextual

**Decision:** When a ready drift value reaches the configured warning
threshold, highlight the drift tile in yellow and label it `DRIFT HIGH`. Do not
replace the prioritized coaching message in the page header.

**Rationale:** Drift is useful live endurance context, but it is not a medical
measurement and should not displace immediate power, heart-rate, cadence, or
sensor guidance.

**Consequences:** The existing threshold setting has a visible, deterministic
effect at and above its boundary. Missing and below-threshold values remain
neutral, and the numeric drift value remains unchanged.

## 2026-08-23 — Offer bounded smoothing for displayed power

**Decision:** Add a 1-30 second moving-average setting in the Power section,
defaulting to 1 second. The filtered value drives both the numeric power display
and its gauge marker. Coaching and aerobic drift continue to use raw current
power. A missing sample clears the rolling history and is displayed as missing.

**Rationale:** Riders can choose a calmer, consistently presented power signal
without changing warning timing or the drift algorithm's sample contract.

**Consequences:** The filter uses a fixed 30-sample buffer and resets when its
window changes or current power becomes unavailable. Existing installations
receive the backward-compatible 1-second property default. The power card shows
the active window as `AVG Ns` beneath `PWR`, so its smoothing is visible while
riding.

## 2026-08-23 — Use a power-first, shape-readable riding dashboard

**Decision:** Keep the light dashboard but replace large colored warning cards
with a stable 38-pixel coaching rail, a 48-pixel two-row summary, and a 5:4:3
power/HR/cadence guidance region. Use black and white for essential meaning;
red, amber, and green are narrow redundant accents. Use explicit target text
and warning badges, an outlined target band, a triangular current marker, and a
distinct HR-ceiling post. The riding view uses no tiny or extra-tiny fonts.

This supersedes the colored-card and equal guidance-card details of the
2026-08-17 adaptive large-type dashboard decision. Its hidden-card behavior,
single-page metric set, and tighter gauge scales remain in force.

**Rationale:** The first physical outdoor test found that small secondary text,
washed-out colored regions, and similar line-based gauge elements were hard to
interpret in sunlight. Power is the primary live control for this product, so
equal visual weight also spent scarce pixels contrary to the product hierarchy.

**Consequences:** Power receives the largest built-in numeric font when its
value fits; HR remains strongly secondary and cadence remains readable but
compact. Persisted warnings remain deterministic and can appear together, but
their cards stay white. Color loss cannot erase the coaching text, warning
badge, target band, current marker, ceiling, or off-scale direction. The
summary uses inline `DRIFT`, `CARBS`, `SPD`, and `TIME` labels without boxed
tiles. Physical Edge 840 sunlight validation remains required.

## 2026-08-23 — Turn the primary metrics into fixed live bars

**Decision:** Replace the card-and-gauge dashboard with three permanently
positioned full-width instruments. Power occupies 118 pixels, HR 72 pixels, and
cadence 62 pixels beneath a 30-pixel coaching rail. Each enabled instrument
fills with color from its drawing minimum through the current value and draws
target or ceiling posts directly inside that region. The number is centered at
the largest fitting built-in numeric font. A 40-pixel telemetry rail shows only
the drift percentage, carbohydrate grams, speed number, and full elapsed time.

This supersedes the 2026-08-23 power-first card layout and its warning badges,
explicit target prose, 5:4:3 redistribution, and labeled summary. It also
supersedes the earlier rule that guidance toggles hide riding cards: power, HR,
and cadence numbers now remain fixed and visible, while disabled guidance
removes only fill, posts, and coaching influence.

**Rationale:** The card revision still presented too much dashboard chrome and
text, making it less glanceable rather than more useful. Combining measurement,
position, target, and warning color into one large instrument spends the screen
on the live numbers and makes each region readable as a single object.

**Consequences:** Coaching copy is shortened to forms such as `POWER UP`,
`POWER DOWN`, `HR HIGH`, and `CAD UP`. The bars retain target position through
bold posts and off-scale direction through filled arrows, so color is
redundant. Metric positions never change during a ride. The footer relies on
stable ordering and familiar `%`, `g`, decimal-speed, and clock formatting
instead of labels. Physical sunlight testing must verify fill contrast, number
legibility across every fill color, and footer recognition.

## 2026-08-23 — Remove drift and equally resize enabled metric bars

**Decision:** Remove aerobic drift calculation, state, settings, properties,
tests, and UI. Show power, HR, and cadence bars only while their corresponding
guidance is enabled; divide the available metric region equally among those
shown. Remove the triangle at each color-to-white fill edge. Divide the footer
equally among carbohydrate target, speed, and elapsed time, preferring the
medium built-in font and falling back only when a value cannot fit its third.

This supersedes all earlier drift decisions and the fixed-position/always-
visible metric behavior from the preceding live-bar decision. Historical drift
entries remain in this log to preserve the record.

**Rationale:** Device review confirmed the live-bar concept but found the edge
triangle redundant, the unequal metric heights unnecessary, and the four-cell
footer too cramped. Drift did not earn its screen space or product complexity.

**Consequences:** One, two, or three enabled metric bars receive respectively
252, 126, or 84 pixels on the Edge 840. Disabling guidance removes that live
metric from the page and enlarges the remainder. The fill boundary itself is
the current-position indicator; off-scale arrows and target posts remain.
Stored drift properties from older installations become unused and are no
longer declared or read. Carbs, speed, and time retain stable footer order.

## 2026-08-23 — Clarify equal values, adaptive footer, and zero under-range

**Decision:** Render power without a `W` suffix and give it the same available
numeric height and `FONT_NUMBER_HOT` preference as HR and cadence. Divide the
footer among visible values: three equal cells for carbs/speed/time or two for
speed/time when fueling is disabled. Convert speed using Garmin's configured
distance units and append `km/h` or `mph` in `FONT_XTINY`. When power or cadence
is below its drawing minimum, draw a 14-pixel amber stub at the left edge in
addition to the off-scale arrow.

**Rationale:** Device screenshots showed that the power unit forced a smaller
fallback font, an empty carbohydrate cell wasted space when fueling was off,
and an unlabeled decimal was not self-evidently speed. A zero-width fill also
made zero power or cadence appear to have no range state.

**Consequences:** All enabled primary metrics use the same large-number sizing
rules. Footer values enlarge when fueling is disabled, and speed respects the
rider's Garmin unit system. Range fill color reflects the live value rather
than waiting for coaching persistence; coaching timing and cadence suppression
while coasting remain unchanged. The amber stub communicates below-scale
position without issuing a cadence instruction.

## 2026-08-23 — Remove coaching and label raw power as 1s

**Decision:** Remove the coaching engine, header, runtime state, warning-delay
properties, and warning-delay settings. Use live bar fill color, target posts,
off-scale arrows, and numeric values as the complete guidance surface. Reclaim
the former 30-pixel header for the enabled metric bars. Display every power
moving-average window uniformly as `Ns`, including `1s` instead of `RAW`.

This supersedes all earlier coaching-state, priority, persistence, header-copy,
and HR-veto decisions. Historical entries remain in this log.

**Rationale:** After the live bars gained clear range color and position, the
text header duplicated the same information while consuming valuable vertical
space. `1s` is also more consistent and directly comparable with every other
moving-average selection.

**Consequences:** One, two, or three enabled metric bars now receive 282, 141,
or 94 pixels respectively on Edge 840. Range colors react directly to the live
displayed values with no warning delay. Zero cadence while coasting can show
below-range color context but never produces a textual instruction. Existing
persisted delay values become unused and are no longer declared or read.

## 2026-08-23 — Distinguish activity averages with outlined triangles

**Decision:** Show Garmin's activity average for power, heart rate, and cadence
as a small black downward-pointing triangle at the bottom edge of each metric
gauge. Render a slightly larger white triangle beneath it, clamp only its visual
position to that gauge's drawing range, and omit it when Garmin does not provide
an average.

**Rationale:** The live value already owns the color-fill edge, while bold posts
rising from the bottom communicate coaching targets. The white knockout keeps
the compact marker recognizable when it overlaps or approaches one of those
posts, while the distinct silhouette remains readable over every status color.

**Consequences:** Each enabled primary field adds ride-average context without
additional text or settings. The marker is positional only; it does not alter
the displayed live value or any guidance behavior.
