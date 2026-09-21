# Automatic Distance Measurement Research

ShotLab currently uses marked-court presets or a custom distance slider. Fully
automatic camera-to-court distance is possible, but it needs more visual
calibration than the current ball/rim/player detector provides.

## Recommendation

Start with a guided visual calibration flow before attempting fully automatic
distance:

1. Ask the player to keep the phone fixed in landscape.
2. Detect the rim and backboard area from the camera preview.
3. Ask the player to tap two known court points, such as the free-throw line and
   rim center, or two lane/court markings.
4. Use the known real-world spacing between those points to estimate scale.
5. Save the estimated distance with the session and let the player override it.

This keeps the feature explainable and testable without requiring depth sensors
or a more complex court-line model.

## Options Considered

| Option | Pros | Cons | Verdict |
| --- | --- | --- | --- |
| Manual presets | Reliable, already implemented, no extra CV risk | Depends on player selecting the right mark | Keep as fallback |
| Tap two known court points | Works with normal cameras, transparent to users | Needs a guided UI and known markings in frame | Best first upgrade |
| Detect court lines automatically | Lower friction when it works | Needs court-line segmentation and varied-court training data | Later |
| Estimate from rim size | No user taps needed | Rim pixel size varies with zoom, angle, and partial occlusion | Not reliable enough alone |
| ARCore depth/plane data | Can estimate real-world scale | Android-only complexity, not always available near courts | Optional later |

## First Implementation Shape

- Add a calibration mode inside the live stats sheet or pre-session setup.
- Pause shot tracking while calibration is active.
- Show the camera frame with two tap targets.
- Let the user choose the known measurement:
  - free throw to rim: `4.57 m`
  - FIBA three-point to rim: `6.75 m`
  - NBA three-point to rim: `7.24 m`
  - custom known spacing
- Compute meters-per-preview-pixel from the two taps.
- Store the result as a normal `CourtCalibration`.

## Acceptance Checks

- The calibration result is within 0.5 m of the marked preset from the same
  phone position.
- The player can override or clear the automatic estimate.
- Calibration does not start image inference while tracking is paused.
- Saved sessions preserve the estimated distance just like manual presets.
- The UI explains which two points to tap without requiring basketball-CV
  knowledge.

## Later Data Needed

- Screenshots from at least three court types: indoor hardwood, outdoor painted
  court, and low-light court.
- Phone positions from sideline, baseline, and diagonal corner angles.
- Comparison table: manual preset distance vs guided estimate.
