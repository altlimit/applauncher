import 'package:flutter/material.dart';
import 'package:applauncher/my_app.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preference.load();
  await Util.init();
  runApp(MyApp(key: Store.myAppStateKey));
}
