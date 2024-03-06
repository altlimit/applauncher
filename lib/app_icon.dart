import 'dart:math';

import 'package:flutter/material.dart';
import 'package:android_intent/android_intent.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/store.dart';

class AppIcon extends StatelessWidget with Store {
  AppIcon({this.appItem, this.coord});

  final AppItem? appItem;
  final Point? coord;

  // Used for displaying an actual app and it's image and handle the onTap event
  @override
  Widget build(BuildContext context) {
    var isDarkMode = Preference.getBool(settingsDarkMode);
    var selected = coord != null && appDrawerState!.appLoc[0] == coord!.x && appDrawerState!.appLoc[1] == coord!.y;
    if (selected) {
      appDrawerState!.selectedApp = appItem;
    }
    return GestureDetector(
        onTap: () {
          if (appDrawerState!.isSelecting) {
            appDrawerState!.toggleSelectedApp(appItem);
          } else {
            appItem!.openApp();
          }
        },
        onLongPress: () {
          showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                var category = appDrawerState!.getAppCategory(appItem);
                var choices = <Widget>[
                  ListTile(
                    leading: new Container(
                        width: 24,
                        height: 24,
                        child: Image.memory(appItem!.icon!)),
                    title: Text(appItem!.name!),
                    subtitle: category != null ? Text(category.name!) : null,
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('App Info'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      var intent = AndroidIntent(
                          action:
                              'android.settings.APPLICATION_DETAILS_SETTINGS',
                          category: 'android.intent.category.DEFAULT',
                          data: 'package:' + appItem!.package!);
                      await intent.launch();
                    },
                  ),
                  ListTile(
                    leading: Container(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                            Util.asset('assets/app_play_store.png'))),
                    title: Text('Google Play'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await Util.launchPlayStore(appItem!.package!);
                    },
                  )
                ];

                if (!appItem!.system!) {
                  choices.add(ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Uninstall'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      var intent = AndroidIntent(
                          action: 'android.intent.action.UNINSTALL_PACKAGE',
                          data: 'package:' + appItem!.package!);
                      await intent.launch();
                    },
                  ));
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: choices,
                );
              });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(child:Container(
                decoration: appDrawerState!.isSelecting && appItem!.selected || selected
                    ? BoxDecoration(color: Colors.blueGrey)
                    : null,
                padding: EdgeInsets.all(10.0),                
                child: Image.memory(appItem!.icon!, fit: BoxFit.fill))),
            Text(
              appItem!.name!,
              style: TextStyle(
                  fontSize: 12.0, color: isDarkMode ? null : Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            )
          ],
        ));
  }
}
