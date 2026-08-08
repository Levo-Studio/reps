# Reps

A minimalist replacement for tracking gym workouts in Apple Notes.

A product by Levo Studio.

## Features

- Routines with a freely-editable list of exercises
- Per-set logging (weight + reps, or reps-only) through inline numeric entry
- Only the best weight/reps per exercise carries over as a baseline — no history, no stats, no streaks
- Automatic rest timer with a Lock Screen Live Activity and an in-app focused rest view
- End-of-workout summary card you can save to Photos
- Siri Shortcuts / Action Button deep-links per routine
- Fully local (SwiftData) — no account, no backend, no cloud sync

## Requirements

- iOS 17.0+
- Xcode 26+ (uses an Icon Composer `.icon` app icon and modern SwiftData)
- Apple frameworks only — no external dependencies

## Setup

1. Clone the repository.
2. Open `Reps.xcodeproj` in Xcode.
3. Select an iOS 17+ simulator or a connected device.
4. Build & run.

### Live Activities (manual step)

The Lock Screen rest-timer Live Activity requires a Widget Extension target, which does not exist in the checked-in project yet. To enable it:

1. In Xcode, go to **File ▸ New ▸ Target ▸ Widget Extension**.
2. Name it `RepsWidget` and enable **Include Live Activity**.
3. Delete the template's generated Swift files.
4. Add the source files from the repo's `RepsWidget/` folder to the new target.
5. Add `Reps/Activities/RestActivityAttributes.swift` to the widget target's membership (it is shared between the app and the widget).

A custom rest-complete sound requires adding an audio file named `RestComplete.caf` to the app target's resources. Without it, iOS uses the default tone.

## Project Structure

```
Reps/
  Models/       SwiftData Routine & Exercise, in-memory WorkoutSession,
                exercise catalog, seeder, and model container
  Views/        All SwiftUI screens
  Intents/      App Intents / Shortcuts deep-links
  Activities/   Shared Live Activity attributes
  Timer/        Rest timer controller
  Theme/        Design tokens
RepsWidget/     Live Activity widget sources (added to a manually-created target)
```

## License

Reps is **source-available** software — it is not open source. © Levo Studio.

Viewing and personal, non-commercial use only. Modification, redistribution, sublicensing, and commercial use are not permitted. See [LICENSE](LICENSE) for the full terms.
