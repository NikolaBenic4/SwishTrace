# YOLOv10 Mobile Path

ShotLab will run object detection on the phone and keep raw video off the
backend. The first production target is a small YOLOv10 model exported to
TensorFlow Lite.

## Decision

- Start with `YOLOv10-N` because it is the smallest official YOLOv10 variant.
- Fine-tune it for only the classes ShotLab needs first: `player`, `ball`, and
  `rim`.
- Export to `TFLite` for Flutter using `tflite_flutter`.
- Keep `CoreML` as a later iOS optimization path only after the TFLite version
  works end to end.
- Use 640x640 input first, then test 416x416 or 320x320 if real devices cannot
  keep up.

## Export Command

After training or fine-tuning, export the model with Ultralytics:

```bash
yolo export model=best.pt format=tflite imgsz=640 int8=True data=shotlab.yaml
```

If end-to-end YOLOv10 output is hard to parse in Flutter, export a traditional
post-processing variant and do confidence filtering/NMS in Dart:

```bash
yolo export model=best.pt format=tflite imgsz=640 int8=True data=shotlab.yaml end2end=False
```

## App Asset Contract

Place the exported model here:

```text
assets/models/yolov10n_shotlab.tflite
```

The labels file already exists at:

```text
assets/models/labels.txt
```

The Flutter service entry point is:

```text
lib/services/shot_detector_service.dart
```

## Current Implementation

The camera-to-inference path is complete:

1. `SessionCameraPreview` streams camera frames while tracking is active.
2. Frames are rotated, resized, and normalized for the 640x640 model input.
3. `ShotDetectorService` runs inference off the UI isolate.
4. Ball, player, and rim boxes are mapped back onto the full-screen preview.
5. `ShotEventTracker` converts ball/rim trajectories into makes and misses.
6. Saved sessions include average inference time and per-class frame
   visibility percentages for court-validation evidence.

The remaining step is the physical 20-shot validation in
`COURT_VALIDATION.md`. Do not tune thresholds until that run produces data.

## Sources

- YOLOv10 official repository: https://github.com/THU-MIG/yolov10
- Ultralytics export documentation: https://docs.ultralytics.com/modes/export
- TFLite Flutter package: https://pub.dev/packages/tflite_flutter
