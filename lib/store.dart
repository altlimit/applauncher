import 'package:flutter/material.dart';
import 'package:applauncher/app_drawer_page.dart';
import 'package:applauncher/my_app.dart';

mixin Store {
  static final appDrawerStateKey = GlobalKey<AppDrawerState>();
  static final myAppStateKey = GlobalKey<MyAppState>();

  AppDrawerState? get appDrawerState {
    return appDrawerStateKey.currentState;
  }

  MyAppState? get myAppState {
    return myAppStateKey.currentState;
  }
}
