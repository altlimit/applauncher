import 'package:applauncher/category_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/store.dart';
import 'package:applauncher/category_select_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPage createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> with Store {
  final _db = DBProvider();

  late bool _isLoaded;
  late bool _isDrawerRight;
  late bool _isDarkMode;
  String? _appName;
  late String _packageName;
  late String _version;
  late String _buildNumber;

  @override
  void initState() {
    super.initState();
    _isLoaded = false;
    _isDrawerRight = false;

    setState(() {
      _isDrawerRight = Preference.getBool(settingsDrawerRight);
      _isDarkMode = Preference.getBool(settingsDarkMode);
      _isLoaded = true;
      final packageInfo = Util.packageInfo;
      _appName = packageInfo.appName;
      _packageName = packageInfo.packageName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _clearDbShowDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Clear Database"),
          content: new Text(
              "You will lose all app changes you have made. Are you sure?"),
          actions: <Widget>[
            new TextButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new TextButton(
              child: new Text("OK"),
              onPressed: () async {
                Navigator.of(context).pop();
                appDrawerState!.clearDB();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Privacy Policy"),
          content: new Text(privacyPolicy),
          actions: <Widget>[
            new TextButton(
              child: new Text("Decline"),
              onPressed: () {
                Navigator.of(context).pop();
                Preference.setBool(settingsPrivacyAccepted, false);
              },
            ),
            new TextButton(
              child: new Text("Accept"),
              onPressed: () async {
                Navigator.of(context).pop();
                Preference.setBool(settingsPrivacyAccepted, true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> settingsWidgets;

    if (_isLoaded) {
      settingsWidgets = <Widget>[
        SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Set theme brightness to dark.'),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
              Preference.setBool(settingsDarkMode, value);
              myAppState!.updateTheme();
            }),
        SwitchListTile(
            title: const Text('Right Side Drawer'),
            subtitle: const Text('Move the category drawer to the right.'),
            value: _isDrawerRight,
            onChanged: (bool value) {
              setState(() {
                _isDrawerRight = value;
              });
              Preference.setBool(settingsDrawerRight, value);
              appDrawerState!.updatePrefs();
            }),
        ListTile(
          title: const Text('Hide Categories'),
          subtitle: const Text('Hide categories from drawer'),
          onTap: () async {
            var categories = await _db.getCategories(all: true);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategorySelectPage(
                    categories: categories,
                    multiSelect: true,
                    selected: categories.where((c) => c.hidden!).toList(),
                    onSelect: (cats) async {
                      await _db.hideCategories(cats);
                      await appDrawerState!.loadCategories(force: true);
                    }),
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Manage Categories'),
          subtitle: const Text('Update or delete custom categories'),
          onTap: () async {
            var categories = await _db.getCategories(all: true);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategorySelectPage(
                    categories:
                        categories.where((c) => !c.isBuiltIn()).toList(),
                    multiSelect: false,
                    onSelect: (selected) async {
                      var category = selected as CategoryItem;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CategoryEditPage(
                                  category: category,
                                  allCategories: categories)));
                    }),
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Create Category'),
          subtitle: const Text('Create custom category'),
          onTap: () async {
            var categories = await _db.getCategories(all: true);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CategoryEditPage(
                        allCategories: categories,
                        category: CategoryItem.fromMap({
                          columnCategoryName: "",
                          columnCategoryKey: "",
                          columnCategoryInfo: "",
                          columnCategoryType: CategoryItem.TYPE_MIXED,
                          columnCategoryPinned: false,
                          columnCategoryHidden: false
                        }))));
          },
        )
        // ListTile(
        //   title: Text('Drawer Settings'),
        //   subtitle: Text('Configure app drawer settings.'),
        //   onTap: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => DrawerSettingsPage(),
        //       ),
        //     );
        //   },
        // ),
      ];

      settingsWidgets.add(ListTile(
        title: const Text('Clear Database'),
        onTap: () {
          _clearDbShowDialog();
        },
        subtitle:
            const Text('Clears the database and start an auto categorization.'),
      ));

      settingsWidgets.add(ListTile(
          title: const Text("Email Support"),
          subtitle: const Text(
              "Found issues? Send a quick email on what's happening."),
          onTap: () {
            Util.launchEmailSupport();
          }));

      if (Util.isFreeVersion) {
        settingsWidgets.add(ListTile(
          title: const Text('Buy Premium'),
          subtitle: const Text('Unlocks all features.'),
          onTap: () {
            Util.launchPremium();
          },
        ));
      }
    } else {
      settingsWidgets = <Widget>[CircularProgressIndicator()];
    }

    settingsWidgets.add(ListTile(
        title: const Text('Privacy Policy'),
        onTap: () {
          _showPrivacyDialog();
        }));

    if (_appName != null) {
      settingsWidgets.add(ListTile(
        title: Text('About ' + _appName!),
        subtitle: Text(
            'v' + _version + ' BUILD:' + _buildNumber + ' PKG:' + _packageName),
        onTap: () {
          Util.launchAbout();
        },
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: settingsWidgets,
      ),
    );
  }
}
