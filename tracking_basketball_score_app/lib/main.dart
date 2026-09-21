import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/basketball_score_app.dart';

export 'app/basketball_score_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BasketballScoreApp());
}
