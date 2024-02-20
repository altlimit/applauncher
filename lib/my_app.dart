import 'package:flutter/material.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/app_drawer_page.dart';
import 'package:applauncher/app_settings_page.dart';
import 'package:applauncher/store.dart';

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with Store {
  late bool _isDarkMode;
  @override
  void initState() {
    super.initState();
    updateTheme();
  }

  updateTheme() {
    setState(() {
      _isDarkMode = Preference.getBool(settingsDarkMode);
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'AppLauncher+',
        theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            brightness: _isDarkMode ? Brightness.dark : Brightness.light),
        initialRoute: '/',
        routes: {
          '/': (context) => AppDrawerPage(
              key: Store.appDrawerStateKey, title: 'AppLauncher+'),
          '/settings': (context) => SettingsPage(),
        });
  }
}
