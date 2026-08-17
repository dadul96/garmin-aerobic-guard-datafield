# Reusable Connect IQ numeric keypads

This directory is a self-contained reference export for Garmin Connect IQ
applications that need direct numeric entry instead of a long scrolling
`Picker` or `Menu2` list. It is deliberately application-agnostic: copy
`ReusableNumericKeypad.mc` into the target project's source path, then connect
accepted values to that application's state in a listener.

The export provides two concrete keypads:

- `ReusableIntegerKeypad`: non-negative whole numbers with a 3×4 keypad.
- `ReusableDecimalKeypad`: non-negative values at fixed 0.1 resolution with a
  3×5 keypad. The fifth row is a full-width OK button, leaving separate
  backspace, zero, and decimal-point controls in the fourth row.

Both variants support touchscreen input and Up/Down/Enter hardware buttons.
They share the same responsive renderer, range validation, Back cancellation,
night-mode palette, and repaint workaround.

## Component boundary

The file contains:

- `ReusableIntegerKeypad` and `ReusableDecimalKeypad`, the public views callers
  construct.
- `ReusableNumericKeypadBase`, shared input/rendering logic that normally does
  not need to be instantiated directly.
- `ReusableNumericKeypadDelegate`, shared touch and button handling.
- `ReusableNumericKeypadListener`, the host integration boundary.

The component does not import `Toybox.Application`, know property keys, or
write persistent data. The listener must perform persistence, domain-specific
validation, derived-state refreshes, and menu-label updates.

Monkey C classes occupy the global namespace unless the target uses modules.
Rename or prefix these classes if the destination project has conflicts.

## Integer keypad example

The integer listener receives a `Number` through the generic `Numeric`
callback:

```monkeyc
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class IntegerSettingListener extends ReusableNumericKeypadListener {
    function onNumericKeypadAccepted(value as Numeric) as Void {
        Application.Properties.setValue("integerSetting", value as Number);
    }
}

var current = Application.Properties.getValue("integerSetting") as Number?;
var keypad = new ReusableIntegerKeypad(
    "Integer setting",
    0,
    1000,
    current
);

WatchUi.pushView(
    keypad,
    new ReusableNumericKeypadDelegate(
        keypad,
        new IntegerSettingListener()
    ),
    WatchUi.SLIDE_LEFT
);
```

The minimum and maximum are inclusive. The first digit replaces the initial
value. An initial `null` displays `--`. OK rejects empty and out-of-range input.

## One-decimal keypad example

The decimal listener receives a `Float`. Constructor values are converted to
integer tenths internally so editing and bounds remain on an exact 0.1 grid:

```monkeyc
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class DecimalSettingListener extends ReusableNumericKeypadListener {
    function onNumericKeypadAccepted(value as Numeric) as Void {
        Application.Properties.setValue("decimalSetting", value.toFloat());
    }
}

var current = Application.Properties.getValue("decimalSetting") as Float?;
var keypad = new ReusableDecimalKeypad(
    "Decimal setting",
    50.0f,
    120.0f,
    current
);

WatchUi.pushView(
    keypad,
    new ReusableNumericKeypadDelegate(
        keypad,
        new DecimalSettingListener()
    ),
    WatchUi.SLIDE_LEFT
);
```

The keypad displays exactly one fractional digit for an initial value and
accepts zero or one typed fractional digit. Pressing decimal first replaces the
initial value with `0.`. Extra decimal points and additional fractional digits
are ignored. Supply constructor bounds and initial values already rounded to
one decimal place; the component converts them to tenths using non-negative
half-up rounding.

## Touch and button behavior

Touch input activates the cell at the tap coordinates. Taps above or outside
the keypad are consumed without activating a cell.

On button devices:

- OK is initially focused so Enter can accept an unchanged initial value.
- Down moves forward through every control and wraps after OK.
- Up moves backward and wraps before the first digit.
- Enter or Start activates the focused control.
- Back calls `onNumericKeypadCancelled()` and pops the view without accepting.

The visible focused cell uses inverted colors. Up/down swipes can also move the
focus on devices that map those gestures to page behaviors.

### Important: do not implement `onSelect()` in the delegate

Garmin can map a touchscreen tap to `BehaviorDelegate.onSelect()`. If the
delegate uses `onSelect()` for hardware Enter while OK is initially focused,
the first tap may activate OK instead of the digit that was touched.

The provided delegate fixes this by separating the paths:

- `onTap()` handles touch strictly by coordinates.
- `onKey()` handles physical Up, Down, Enter, and Start.
- There is intentionally no `onSelect()` override.

Preserve this separation when adapting the component. This behavior was found
in the Connect IQ simulator and is exactly the kind of input-dispatch detail
that successful compilation will not reveal.

## Repaint behavior

After an edit or focus move, the delegate calls:

```monkeyc
WatchUi.switchToView(keypad, delegate, WatchUi.SLIDE_IMMEDIATE);
```

This replaces only the current top view and preserves its model plus the view
below it. A plain `WatchUi.requestUpdate()` was observed to leave a pushed
data-field settings view visually stale on physical Edge hardware even though
input and persistence continued to work. Keep the immediate replacement unless
testing on every target proves another refresh path reliable. Confirm that Back
still returns to the expected view below the keypad.

## Required adaptation checks

Before integrating into another application, review:

1. **API and products:** Check the destination manifest's minimum API and all
   device input models. The component uses `System.getDeviceSettings()`, night
   mode, `BehaviorDelegate.onKey()`, and touch events.
2. **Screen geometry:** Layout scales from `Dc` width and height, but fonts,
   tap comfort, and the five-row decimal layout still need inspection at every
   supported resolution.
3. **Numeric domain:** Both variants are non-negative. The decimal variant is
   fixed at one fractional digit. Signs, more precision, arbitrary increments,
   locale-specific decimal separators, or blank-as-unconfigured semantics need
   explicit changes.
4. **Text and localization:** `OK`, `ENTER`, `.`, and `<` are embedded strings
   or symbols. Move them to the host's resources and choose an appropriate
   decimal separator when localization is required.
5. **Theme:** The default palette follows `isNightModeEnabled`. Adapt it if the
   host has its own theme or accessibility rules.
6. **Persistence:** Save only in the listener. Refresh any host settings model
   after acceptance and decide whether the containing settings view should
   remain open or close.
7. **Defensive validation:** Repeat range, type, precision, and domain checks
   when loading stored values. UI validation must not be the only protection
   against malformed or externally edited properties.
8. **View lifecycle:** Verify immediate replacement, acceptance pop, Back pop,
   and the underlying view stack in the actual host context.

## Suggested tests

Add pure tests for both variants:

- first digit replacing the initial value;
- `null` initial state;
- digit-length enforcement;
- backspace on populated and empty input;
- inclusive minimum/maximum acceptance;
- empty, below-minimum, and above-maximum rejection;
- decimal-first input, duplicate decimal, and one-digit precision;
- all touch regions and coordinates outside the grid;
- initial OK focus, Up/Down movement, and wraparound;
- listener acceptance and cancellation;
- regression that the first tap activates its touched cell, not focused OK.

Compile with the destination repository's supported wrapper and full gate.
Compilation alone does not prove input behavior: test at least one touchscreen
and every distinct button model in the simulator, then repeat critical repaint
and navigation checks on physical hardware when possible.
