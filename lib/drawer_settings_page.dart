import 'package:flutter/material.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/app_grid.dart';

class DrawerSettingsPage extends StatefulWidget {
  final double? initialSize;

  DrawerSettingsPage({this.initialSize});

  @override
  _DrawerSettingsState createState() => _DrawerSettingsState();
}

class _DrawerSettingsState extends State<DrawerSettingsPage> {
  final DBProvider db = DBProvider();
  List<AppItem>? _apps;

  @override
  @override
  void initState() {
    super.initState();

    db.getAppsBy(limit: 10).then((apps) {
      setState(() {
        _apps = apps;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          Expanded(child: AppGrid(apps: _apps)),
          // Expanded(
          //     child: Slider(
          //   activeColor: Colors.indigoAccent,
          //   min: 0.0,
          //   max: 50.0,
          //   onChangeEnd: (newSize) {
          //     debugPrint('NewSize: ' + newSize.toString());
          //     // setState(() => _iconSize = newSize);
          //   },
          //   onChanged: (newSize) {},
          //   // value: _iconSize,
          // ))
        ]));
  }
}
