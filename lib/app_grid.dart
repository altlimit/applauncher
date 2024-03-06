import 'dart:math';

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
    return OrientationBuilder(builder: (context, orientation) {
      var xCount = 5 * (orientation == Orientation.portrait ? 1 : 2);
      return GridView.builder(
        primary: true,
        itemCount: apps!.length,
        padding: EdgeInsets.all(getDouble('padding', 10.0)!),
        shrinkWrap: false,
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: getDouble('horizontal_space', 2.5)!,
            crossAxisCount: getInt('item_count', xCount)!,
            childAspectRatio: getDouble('aspect_ratio', .8)!),
        itemBuilder: (BuildContext context, int index) {
          var x = index / xCount;
          x = x - x.truncate();
          return AppIcon(appItem: apps![index], coord: Point((x * xCount).round(), (index / xCount).floor()),);
        });
    });
  }
}
