# ShotLab Court Validation

Use this test before changing detection or shot-event thresholds. Keep the
phone position fixed for the full run.

## Setup

1. Install the latest debug APK on the test phone.
2. Place the phone in landscape with the shooter, ball, and rim visible.
3. Select the correct court zone and marked distance.
4. Confirm the ball and rim overlays remain aligned while moving.
5. Record the average displayed inference time.

The live statistics sheet now shows the session-wide average inference time
and ball, rim, and player frame visibility. These diagnostics are saved with
the session, so record them in the Results section after the run.

## 20-Shot Test

Shoot 20 attempts with a known ground-truth result. Include:

- 10 makes and 10 misses.
- At least 3 rim or backboard misses.
- At least 3 clean makes.
- At least 2 shots where the ball briefly leaves the frame.

| Shot | Actual | App | Ball visible | Rim stable | Duplicate count | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 |  |  |  |  |  |  |
| 2 |  |  |  |  |  |  |
| 3 |  |  |  |  |  |  |
| 4 |  |  |  |  |  |  |
| 5 |  |  |  |  |  |  |
| 6 |  |  |  |  |  |  |
| 7 |  |  |  |  |  |  |
| 8 |  |  |  |  |  |  |
| 9 |  |  |  |  |  |  |
| 10 |  |  |  |  |  |  |
| 11 |  |  |  |  |  |  |
| 12 |  |  |  |  |  |  |
| 13 |  |  |  |  |  |  |
| 14 |  |  |  |  |  |  |
| 15 |  |  |  |  |  |  |
| 16 |  |  |  |  |  |  |
| 17 |  |  |  |  |  |  |
| 18 |  |  |  |  |  |  |
| 19 |  |  |  |  |  |  |
| 20 |  |  |  |  |  |  |

## Pass Criteria

- At least 18 of 20 results counted correctly.
- No more than one missed shot event.
- No duplicate counts.
- Ball visible on at least 18 shots.
- Rim stable for the full ball approach on at least 18 shots.
- Average inference time stays below 400 ms.
- No crash or camera freeze during a five-minute session.

## Results

- Correct results:
- Missed events:
- False makes:
- False misses:
- Duplicate counts:
- Average inference time:
- Ball frame visibility:
- Rim frame visibility:
- Player frame visibility:
- Five-minute stability:
- Phone position and distance:
- Lighting:

Do not tune multiple thresholds at once. Change one behavior, repeat the same
20-shot setup, and compare results.
