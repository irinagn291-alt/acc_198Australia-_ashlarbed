# Ashlarbed

Log a set on the tower and bed the session into climbable floors.

Ashlarbed is for lifters who will log if the week becomes a building. Home is the steeple: an open scaffold that rises with each set, then a Bed that writes 500 kg storeys, carries the remainder, and stamps an earned PR. No account, no feed, no Game tab.

## Architecture

The domain is a Scaffold ADT with three cases — Open, Bedded, and Rest. The Steeple is the fold of that ADT over Sets, not a list of workouts.

`writeSet` always appends a Set to today’s Open scaffold and adds tonnage equal to weight times reps. It never inserts a Storey. `bedSession` is the only fold that writes Storeys: it divides Open tonnage into floors of 500 kg, carries remainder under 500 kg as the next day’s Open stub keyed by Int YYYYMMDD, and stamps an Epley 1RM (`weight × (1 + reps / 30)`) or raw-weight PR onto those new storeys only when the number is actually beaten. Bedding Open with no Sets writes a RestBand instead of a floor. Daily floor goal equals experience times aim.

One `SteepleStore` owns mutation. Views bind to `SteepleWatch` and never talk to UserDefaults. Persistence is a Codable snapshot under `asb.steeple.v1`, with an Application Support file as the atomic projection.

This pattern fits the product: a set is timber on the scaffold, and Bed is the mason’s commit. A tab plus a workout table would skip the fold.

## Scaffold-then-bed

This is why someone would pick the app. Every set writes onto today’s Open scaffold. The home verb is **Bed the session** — a full-width control on the Tower tab — and that commit is the only write that creates climbable Storeys, carries the remainder, stamps earned PRs, and scores the day against the floor goal. Bedding with no sets writes a rest band so rest is a real course, not a missing row. Analytics counts bedded floors, volume, and PR stamps.

## Design

Sage botanical calm. Palette lives in `Assets.xcassets` and is reached only through `AshlarSwatch`: background `#FAF4F6`, surface `#FEFDFE`, ink `#391821`, accent `#C3224B`, muted `#8D5E6A`. Type is SF Pro behind `AshlarFace` — six steps, never above 34 pt. Card radius 22 pt, chip radius 14 pt, one soft shadow. Spacing unit 8 pt. Tap targets 44 pt. Custom drawing is confined to the climbable steeple on Tower.

Navigation is steeple-tab chrome: Tower, Analytics, Settings. Bed is a control on Tower, not a destination.

## Art

Style: botanical illustration (copperplate-engraving quality, climbing vines on dressed ashlar).

Base prompt reused for every asset:

```
Botanical illustration in copperplate-engraving quality: fine line, stipple, and hatch, herbarium-plate composure, climbing vines on dressed ashlar, scientific field-guide calm, generous negative space, no text, no letters, no logo
```

| Image set | Prompt |
| --- | --- |
| `asb_AppIcon` | A small climbable ashlar steeple with a climbing vine, centred, filling the canvas edge to edge, botanical engraving, no text, no letters, no rounded corners, no alpha |
| `asb_Splash` | A tall vertical herbarium plate of a stone steeple wrapped in climbing vines, quiet uncluttered middle third, botanical engraving, no text |
| `asb_Onboarding1` | A person standing before an unfinished ashlar steeple, botanical engraving cutout, the product in one glance. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_Onboarding2` | Hands bedding a dressed stone course onto a scaffold with a trowel, botanical engraving cutout, the primary verb mid-gesture. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_Onboarding3` | A tall bedded steeple of many stone courses with one stamped storey, botanical engraving cutout, accumulated meaning. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_EmptyHome` | An unfinished steeple with no courses laid, a quiet scaffold waiting, botanical engraving cutout, calm and inviting. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_EmptyList` | A blank course ledger or empty ashlar niche, botanical engraving cutout. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_CardBackdrop` | Abstract botanical hatch of vine and dressed stone, low contrast, filling the canvas so text can sit on top |
| `asb_ControlFace` | The face of a mason's trowel as a single physical control, botanical engraving cutout, isolated. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_TwistHero` | Open wooden scaffold beside newly bedded ashlar courses, botanical engraving cutout, emblem of scaffold-then-bed. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_SuccessMark` | A carved mason's mark stamped into a single dressed stone, botanical engraving cutout, earned confirmation not fireworks. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `asb_HeaderDecor` | A wide herbarium band of climbing vine along a stone cornice, botanical engraving. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |

## How this is not a repeat

This is the first `lift_tower` in the portfolio. Home is a climbable steeple of bedded floors, not a workout table and not CaloriSpire’s food-spire. ProteinGauge and IronMacros are calorie products with lift-day nouns; this app never searches food or assigns a meal slot. A set always writes the live scaffold; Bed is the only write that creates a climbable storey. Mini-ref Rise is a stack that grows from logged work — Ashlarbed keeps that mechanic with a new verb, new types, and a new layout. No wrapper, no crash-tower game.

## Build

```bash
cd Ashlarbed
xcodegen generate
xcodebuild -scheme Ashlarbed -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.ashlarbed.steeple`. Contact: https://ashlarbed-steeple.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `asb.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
