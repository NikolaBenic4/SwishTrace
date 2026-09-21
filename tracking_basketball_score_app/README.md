# ShotLab

ShotLab is a Flutter basketball training app that runs YOLO detection on the
phone, automatically counts makes and misses, and saves local session
analytics, quests, rewards, court zones, distance, and tracked flight times.

## Run locally

```text
flutter pub get
flutter test
flutter analyze
flutter run
```

The TFLite model and labels live in `assets/models/`.

## Current release gate

Run the physical 20-shot test documented in `COURT_VALIDATION.md`. The app
saves average inference latency and ball/rim/player visibility diagnostics
with each session. Threshold tuning and backend work remain intentionally
blocked until the court test provides real data.

See `ROADMAP.md` for project status and sequencing.

Online accounts, friends, challenges, leaderboards, session synchronization,
and the serverless backend are implemented. See `docs/ONLINE_SETUP.md` to
connect Firebase and deploy the AWS SAM stack.

Quests rotate from pools of daily and weekly goals covering makes, attempts,
accuracy, training time, court zones, calibrated shots, and tracked
trajectories.

Training modes have distinct destinations: Live Shot Tracking opens automatic
camera scoring, Distance Challenge begins with distance setup, Friend Battle
opens online play, and Form Session remains clearly marked unavailable until a
pose-keypoint model is connected.

The home profile button opens a lifetime dashboard with overall shooting
statistics, personal records, tracking coverage, recent activity, levels, and
23 progressive achievements.

Distance Challenge begins with an interactive half-court spot picker followed
by distance setup. Every automatic result is stored at that position and
appears later as a green make or red miss. Free Shooting starts directly
without requiring a court position.

Distance Challenge keeps both setup steps in portrait orientation. The app
rotates to landscape only after the court spot and distance are confirmed and
the live camera is ready to open.

After the first shot, a compact court appears in the live camera's bottom-right
corner. Saving opens a dedicated Session Review screen. Recent Profile sessions
open the same review and can filter the court to All, Makes, or Misses.
