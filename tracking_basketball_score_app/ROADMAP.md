# ShotLab Roadmap

Last updated: June 22, 2026.

Use this as a Notion database starter. Suggested properties:
`Status`, `Priority`, `Area`, `Platform`, `Difficulty`, `Notes`, `Target date`.

## Milestone Snapshot

- On-device YOLO detection is integrated and running on a Galaxy S22.
- The app stays portrait while the full-screen tracking session uses landscape.
- Makes and misses are counted automatically from ball/rim trajectories.
- Sessions, court zones, calibrated distance, and per-shot tracked flight times
  are stored locally.
- Progress analytics, daily/weekly quests, points, and badges use saved session
  data instead of mock values.
- The remaining release blocker is the documented 20-shot court validation.

## Current Focus

**Next:** run the documented 20-shot court validation for live detections and
automatic make/miss counting.

Acceptance checks:

- Detection boxes align with the full-screen camera preview. Initial device
  check passed on Galaxy S22; landscape court check pending.
- The ball remains detectable during a real shot.
- The rim and shooter are stable enough across consecutive frames.
- Automatic events count one result per shot without duplicate makes or misses.
- Record false positives, missed shots, and unusual trajectories for threshold
  tuning.
- Inference remains responsive. Initial Galaxy S22 measurement is about
  317 ms per processed frame; five-minute court test still pending.
- Session-wide average inference time and ball/rim/player visibility are now
  recorded with each saved session to support the validation report.

Use `COURT_VALIDATION.md` to record ground truth and app results. After it
passes, tune only the thresholds shown by the data, then implement weak-zone
drill recommendations. Backend work stays deferred until automatic scoring is
court-validated.

## Phase 1 - App Frame

| Task | Status | Area | Priority |
| --- | --- | --- | --- |
| Create mobile home menu with training modes | Done | App UI | High |
| Create live tracking session screen | Done - full-screen camera, score, timer, statistics, and pause control | App UI | High |
| Create progress and quest screens | Done - Progress and Quests use saved local analytics | App UI | Medium |
| Define first stats: makes, misses, percentage, tracked flight time, distance | Done - implemented in live and saved-session analytics | Product | High |

## Phase 2 - Real Tracking

| Task | Status | Area | Priority |
| --- | --- | --- | --- |
| Add mobile camera preview | Done | Camera | High |
| Pick YOLOv10 model export path for mobile | Done | AI | High |
| Connect live camera frames to YOLOv10 TFLite inference | Done | AI | High |
| Validate ball, human, and rim detection runtime on a physical device | Done - camera, model, overlay, and latency passed on Galaxy S22 | AI | High |
| Optimize frame rotation, preview alignment, and inference scheduling | Done | AI | High |
| Keep app portrait and tracking screen landscape | Done | Camera | Medium |
| Build shot-event logic for make and miss detection | Done - automatic trajectory state machine, cooldown, and tests | Tracking | High |
| Add marked-court calibration for shooting distance | Done - free throw, FIBA, NBA, and custom distance | Tracking | High |
| Validate detection and automatic scoring across 20 real shots | Ready for court test - follow `COURT_VALIDATION.md` | QA | High |
| Tune shot-event thresholds from court validation results | Blocked by court test data | Tracking | High |
| Research automatic camera-to-court distance measurement | Done - guided two-point visual calibration recommended in `docs/AUTOMATIC_DISTANCE_MEASUREMENT.md` | Tracking | Medium |

## Phase 3 - Training Intelligence

| Task | Status | Area | Priority |
| --- | --- | --- | --- |
| Save sessions locally | Done - device history stores score, duration, mode, zone, calibrated distance, and shot timing | Data | High |
| Show shot chart by court zone | Done - interactive half-court saves each make/miss position and still aggregates seven zones | Analytics | High |
| Review individual sessions with shot filters | Done - saved-session review supports all shots, makes, and misses | Analytics | Medium |
| Compare makes vs misses by tracked ball-flight time | Done - per-shot timing is saved and aggregated by result | Analytics | Medium |
| Add true hand-release timing with pose keypoints | Tracker implemented and tested; live output blocked until a pose-keypoint model asset is supplied | AI | Medium |
| Recommend next drill based on weak zones | Done - Progress recommends a zone-specific drill from saved shot percentages | Coaching | Medium |

## Phase 4 - Online Mode

| Task | Status | Area | Priority |
| --- | --- | --- | --- |
| Add user accounts | Done in code - Firebase email auth needs project API key | Backend | High |
| Add friend list | Done in code - mobile UI and API endpoint await deployment | Social | Medium |
| Add daily and weekly quests | Done - 8 daily and 8 weekly templates rotate deterministically, with 3 of each active | Game Loop | Medium |
| Add points, badges, and unlocks | Done - local points, levels, badge progress, and unlock previews are calculated from saved sessions | Game Loop | Medium |
| Add friend challenges and leaderboards | Done in code - mobile UI and API endpoints await deployment | Social | Medium |

## Phase 5 - Backend Architecture

Goal: keep operating costs as low as possible by running heavy detection on the phone and sending only lightweight JSON payloads to a serverless backend.

### Recommended Stack

| Layer | Technology | Reason |
| --- | --- | --- |
| Mobile inference | Flutter camera + TFLite YOLOv10 on device | Avoids streaming video to the cloud and keeps cloud costs low. |
| API layer | AWS API Gateway HTTP API | Pay per request, low maintenance, simpler than managing a server. |
| Compute | AWS Lambda | Scales to zero and runs only when saving sessions, quests, or leaderboard updates. |
| Database | AWS DynamoDB on-demand | Handles rapid writes for shots, makes, misses, coordinates, and timestamps without managing database instances. |
| User management | Firebase Auth | Avoids custom password hashing, email verification, and Apple/Google OAuth work. |

### Why This Stack

- Keep raw video local on the device.
- Send only small JSON payloads after shots or sessions.
- Start with API Gateway HTTP API instead of REST API unless REST-only features are needed.
- Use DynamoDB on-demand first because traffic will be unpredictable during early testing.
- Use Firebase Auth tokens in the app and verify them inside Lambda before writing data.
- Add Supabase Auth only if we later choose a Supabase/Postgres backend instead of AWS.

### Example Session Payload

```json
{
  "userId": "firebase-user-id",
  "sessionId": "session-2026-06-10-001",
  "startedAt": "2026-06-10T18:00:00Z",
  "endedAt": "2026-06-10T18:24:00Z",
  "makes": 8,
  "attempts": 10,
  "misses": 2,
  "shootingPercentage": 80,
  "averageTrackedFlightTimeMs": 480,
  "averageDistanceMeters": 6.2
}
```

### Example Shot Event Payload

```json
{
  "sessionId": "session-2026-06-10-001",
  "shotId": "shot-0007",
  "timestamp": "2026-06-10T18:12:14Z",
  "result": "make",
  "trackedFlightTimeMs": 470,
  "distanceMeters": 6.4,
  "courtZone": "right-wing",
  "ballRimConfidence": 0.91,
  "formScore": 84
}
```

### Backend Tasks

| Task | Status | Area | Priority |
| --- | --- | --- | --- |
| Decide final backend stack | Done - AWS SAM/Lambda/DynamoDB with Firebase Auth | Backend | High |
| Design DynamoDB tables for users, sessions, shot events, quests, and leaderboards | Done - documented in `docs/BACKEND_DATA_MODEL.md` | Backend | High |
| Create save-session Lambda endpoint | Done in `backend/src/api.py` | Backend | High |
| Verify Firebase Auth token in Lambda | Done with Firebase Admin | Auth | High |
| Add save-shot-event endpoint for detailed tracking | Done | Backend | Medium |
| Add daily and weekly quest calculation job | Done - scheduled Lambda | Game Loop | Medium |
| Add leaderboard read/write endpoints | Done | Social | Medium |

## Notion Integration Options

1. Manual first: paste this roadmap into Notion and manage tasks there.
2. Semi-automatic: export Notion tasks as CSV and import them into the app later.
3. Full sync later: use the Notion API from a backend service, not directly from the mobile app, so the Notion secret token stays private.
