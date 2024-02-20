import 'package:flutter/material.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/app_icon.dart';

class AppGrid extends StatelessWidget {
  final List<AppItem>? apps;
  final Map<String, dynamic>? config;

  AppGrid({this.apps, this.config});

  hasValue(String key) {
    return config != null && config!.containsKey(key) && config![key] != null;
  }

  double? getDouble(String key, double def) {
    return hasValue(key) ? config![key] : def;
  }

  int? getInt(String key, int def) {
    return hasValue(key) ? config![key] : def;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        primary: true,
        itemCount: apps!.length,
        padding: EdgeInsets.all(getDouble('padding', 10.0)!),
        shrinkWrap: false,
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: getDouble('horizontal_space', 2.5)!,
            crossAxisCount: getInt('item_count', 5)!,
            childAspectRatio: getDouble('aspect_ratio', .8)!),
        itemBuilder: (BuildContext context, int index) {
          return AppIcon(appItem: apps![index]);
        });
  }
}
