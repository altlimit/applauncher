import 'package:flutter/material.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/store.dart';

class AppDrawer extends StatelessWidget with Store {
  final List<CategoryItem>? categories;
  final List<AppItem>? apps;

  AppDrawer({this.categories, this.apps});

  List<CategoryItem> filteredCategories() {
    var catMap = Map<String, CategoryItem>();
    if (categories != null) {
      categories!.forEach((category) {
        if (category.type == CategoryItem.TYPE_MIXED) category.appCount = 0;
        catMap[category.key!] = category;
      });
      categories!.forEach((category) {
        if (category.type == CategoryItem.TYPE_MIXED) {
          if (category.info != null && category.info!.length > 0) {
            catMap[category.key]!.appCount = category.info!.split(',').fold(
                0,
                (t, c) =>
                    t! + (catMap.containsKey(c) ? catMap[c]!.appCount! : 0));
          }
          if (category.key == gamesCategory) {
            catMap[category.key]!.appCount = catMap.keys.fold(
                0,
                (t, k) =>
                    t! +
                    (k.toUpperCase().contains('GAME')
                        ? catMap[k]!.appCount!
                        : 0));
          }
        } else if (category.type == CategoryItem.TYPE_PACKAGE) {
          if (category.info != null && category.info!.length > 0) {
            catMap[category.key]!.appCount = category.info!.split(',').fold(
                0,
                (t, c) =>
                    t! + apps!.where((a) => a.package!.contains(c)).length);
          }
        }
      });

      return categories!
          .where((category) =>
              !category.hidden! &&
              (category.appCount! > 0 ||
                  category.type == CategoryItem.TYPE_PACKAGE ||
                  category.key == recentCategory ||
                  category.key == frequentCategory))
          .toList();
    }

    return new List<CategoryItem>.empty(growable: true);
  }

  int totalApps() {
    return filteredCategories().fold(
        0, (t, c) => t + (c.type == CategoryItem.TYPE_NONE ? c.appCount! : 0));
  }

  _appCount(CategoryItem c) {
    return c.appCount! > 0
        ? Text(
            c.appCount.toString(),
            style: TextStyle(color: Colors.grey),
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return new Drawer(
        child: new ListView(
      children: <Widget>[
        new ListTile(
          leading: new Container(
              width: 24.0,
              height: 24.0,
              child: Image.asset(Util.asset('assets/category_apps.png'))),
          title: new Text('All Apps'),
          trailing: _appCount(CategoryItem()..appCount = totalApps()),
          onTap: () {
            appDrawerState!.setCategory(null);
            Navigator.of(context).pop();
          },
          onLongPress: () {
            showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.create_new_folder),
                        title: Text('Create Shortcut'),
                        onTap: () async {
                          Navigator.of(context).pop();
                          await Util.platform.invokeMethod(
                              'createCategoryShortcut', <String, dynamic>{
                            'category_id': -1,
                            'label': 'Apps',
                            'icon': Util.asset('category_apps'),
                            'request_pin': appDrawerState!.shortcutSupport == 2
                          });
                        },
                      )
                    ],
                  );
                });
          },
        )
      ]..addAll(filteredCategories()
          .map((c) => new ListTile(
                subtitle: Text(
                    c.key!.toLowerCase().contains('game') ? 'Games' : 'Apps'),
                leading: c.pinned!
                    ? Icon(Icons.star)
                    : new Container(
                        width: 24.0, height: 24.0, child: c.getImage(null)),
                title: Text(c.name!),
                trailing: _appCount(c),
                onTap: () {
                  appDrawerState!.setCategory(c);
                  Navigator.of(context).pop();
                },
                onLongPress: () {
                  showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        var choices = <Widget>[
                          ListTile(
                            leading: Icon(
                                c.pinned! ? Icons.star_border : Icons.star),
                            title: Text(c.pinned! ? 'Remove Star' : 'Star'),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await c.togglePin();
                              await appDrawerState!.loadCategories(force: true);

                              if (!Util.isFreeVersion &&
                                  appDrawerState!.shortcutSupport! > 1) {
                                if (c.pinned!) {
                                  await Util.platform.invokeMethod(
                                      'createCategoryShortcut',
                                      <String, dynamic>{
                                        'category_id': c.id,
                                        'label': c.name,
                                        'icon': c.getIconKey(null),
                                        // 'icon_data': await c.getIconBytes(),
                                        'request_pin': false
                                      });
                                } else {
                                  await Util.platform.invokeMethod(
                                      'deleteCategoryShortcut',
                                      <String, dynamic>{'category_id': c.id});
                                }
                              }
                            },
                          )
                        ];

                        if (Util.isFreeVersion) {
                          choices.add(ListTile(
                            leading: Icon(Icons.lock),
                            title: Text('Create Shortcut (Premium)'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Util.launchPremium();
                            },
                          ));
                        } else if (appDrawerState!.shortcutSupport == 1 ||
                            appDrawerState!.shortcutSupport == 2) {
                          choices.add(ListTile(
                            leading: Icon(Icons.create_new_folder),
                            title: Text('Create Shortcut'),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await Util.platform.invokeMethod(
                                  'createCategoryShortcut', <String, dynamic>{
                                'category_id': c.id,
                                'label': c.name,
                                'icon': c.getIconKey(null),
                                // 'icon_data': await c.getIconBytes(),
                                'request_pin':
                                    appDrawerState!.shortcutSupport == 2
                              });
                            },
                          ));
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: choices,
                        );
                      });
                },
              ))
          .toList()),
    ));
  }
}
