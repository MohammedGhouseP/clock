# StudyBlock

A time-block task timer built with Flutter — assign a task to a time block
(e.g. "2 hours for study"), start/pause/complete it, and get an end-of-day
report on what was completed, delayed, or failed.

## Features

**Free**
- Create task blocks with title, category, and planned duration
- Start / Pause ("Wait") / Resume / Complete / Give up (Fail) timer per block
- Automatic status detection:
  - `Completed` — finished within ~10% of planned time
  - `Delayed` — finished, but went noticeably over planned time
  - `Failed` — user gave up, or the block was still unfinished when the day
    was finalized
- Behavior tracking per block: pause count, total paused time, actual vs
  planned time
- Today's report: completed/delayed/failed counts, focus efficiency %,
  planned vs actual time

**Premium (gated via `profile.isPremium`)**
- Full multi-day history (Free users only see today's live report)
- Streak tracking (current + longest streak of days with ≥50% completion)
- Text notes per task block
- Voice memo recording + playback per task block

> The premium gate here just flips a local boolean (`Upgrade now` button) so
> you can see both states immediately. Wire it up to `in_app_purchase` /
> RevenueCat / your billing backend for a real paywall — the rest of the app
> already reads `AppProvider.isPremium` everywhere it matters, so there's one
> place to change.

## Architecture

```
lib/
  models/       TaskBlock, DailyReport, UserProfile, TaskStatus enum
  services/     StorageService (SharedPreferences), AudioService (voice memos)
  providers/    AppProvider — single source of truth + the ticking timer
  screens/      Home, AddTask, Timer, Notes, Report, History, Profile
  widgets/      Reusable cards (TaskBlockCard, StatCard, PremiumLockCard)
  utils/        Theme, status label/color/icon helpers
```

State management: `provider` (ChangeNotifier). Storage: local
`shared_preferences`, one JSON blob per day, so history is queryable without
a database. Swap `StorageService` for Hive/SQLite/a backend later without
touching any screen.

## Setup

This delivery is the `lib/` source + `pubspec.yaml` only — no platform
folders (`android/`, `ios/`, etc.), since generating those requires the
Flutter SDK itself, which isn't available in the sandbox this was built in.

1. Create a fresh Flutter project and drop this `lib/` and `pubspec.yaml` in:
   ```bash
   flutter create studyblock
   cd studyblock
   # replace the generated lib/ and pubspec.yaml with the ones from this zip
   flutter pub get
   ```
2. Add microphone permission (required for voice memos):
   - **Android** — in `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <uses-permission android:name="android.permission.RECORD_AUDIO"/>
     ```
   - **iOS** — in `ios/Runner/Info.plist`:
     ```xml
     <key>NSMicrophoneUsageDescription</key>
     <string>StudyBlock needs microphone access to record voice memos for your tasks.</string>
     ```
3. Run it:
   ```bash
   flutter run
   ```

## Known limitations / next steps

- Only one block can be active at a time (starting a new one auto-pauses the
  previous one) — intentional, but flag it if you want parallel timers.
- Voice memo files are stored on-device only; add cloud upload if premium
  users should be able to restore memos on a new device.
- `record` / `audioplayers` package APIs move fast between major versions —
  if `flutter pub get` resolves a newer major version than pinned here,
  double check `AudioService` against that version's docs.
- No push notifications yet for "block running long" or daily report
  reminders — natural next addition given the behavior-tracking data already
  collected.
