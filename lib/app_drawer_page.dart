import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/app_drawer.dart';
import 'package:applauncher/category_select_page.dart';
import 'package:applauncher/app_grid.dart';

class AppDrawerPage extends StatefulWidget {
  AppDrawerPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  AppDrawerState createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawerPage> with WidgetsBindingObserver {
  final DBProvider _db = DBProvider();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(onKey: (node, event) {
    return KeyEventResult.handled;
  },);

  List<int> appLoc = [-1, 0];
  List<AppItem>? _apps;
  List<CategoryItem>? _categories;
  CategoryItem? _selectedCategory;
  late bool _isDrawerRight;
  late bool _isSearching;
  String? _searchKey;
  Completer<Null>? _isLoading;
  Completer<Null>? _isCategorizing;
  AppSort? _appSort;
  AppItem? selectedApp;

  bool isSelecting = false;
  int? shortcutSupport = -1;

  CategoryItem? getAppCategory(AppItem? app) {
    return _categories!.firstWhereOrNull((cat) => cat.id == app!.categoryId);
  }

  loadSelectedApps() async {
    var apps = await _db.getApps(_selectedCategory, sort: _appSort);
    setState(() {
      _apps = apps;
    });
  }

  loadCategories({force = false}) async {
    var categories =
        await _db.getCategories(hidden: _appSort == AppSort.hidden);
    if (force ||
        _categories == null ||
        _categories!.length != categories.length) {
      setState(() {
        _categories = categories;
      });
    }
  }

  setCategory(CategoryItem? category) async {
    setState(() {
      _selectedCategory = category;
      appLoc[0] = -1;
      appLoc[1] = 0;
    });

    debugPrint(
        'setCategory: ' + (category != null ? category.id.toString() : 'null'));
    await loadSelectedApps();
  }

  List<AppItem>? filteredApps() {
    if (_isSearching && _searchKey != null && _searchKey!.length > 0) {
      return _apps!
          .where((app) =>
              app.name!.toLowerCase().contains(_searchKey!.toLowerCase()))
          .toList();
    }
    return _apps;
  }

  Future<Null> _loadApps() async {
    if (!Preference.getBool(settingsPrivacyAccepted)) {
      _showPrivacyAcceptDialog();
      return null;
    }
    if (_isCategorizing != null) {
      return _isCategorizing!.future;
    }
    if (_categories != null) {
      await _checkCategoryParam();
    }
    if (_isLoading != null && !_isLoading!.isCompleted) {
      return _isLoading!.future;
    }
    _isLoading = new Completer<Null>();
    if (_categories == null) {
      await _checkCategoryParam();
    }
    var apps = await _db.getApps(_selectedCategory, sort: _appSort);
    var isNew = apps.length == 0;

    if (!isNew && _apps!.length != apps.length) {
      setState(() {
        _apps = apps;
      });
      await loadCategories();
    }
    var changed = await _db.loadApps();
    if (isNew || changed) {
      await loadSelectedApps();
      await loadCategories();
      _isLoading!.complete();
    } else {
      _isLoading!.complete();
    }

    return _isLoading!.future;
  }

  _initShortcutSupport() async {
    int? ss = await Util.platform.invokeMethod('getShortcutSupport');
    setState(() {
      shortcutSupport = ss;
    });
  }

  clearDB() async {
    await _db.clearDB();
    _selectedCategory = null;
    _categories = null;
    _apps = new List<AppItem>.empty(growable: true);
    _refreshIndicatorKey.currentState!.show();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    isSelecting = false;
    _isDrawerRight = false;
    _apps = new List<AppItem>.empty(growable: true);
    _selectedCategory = null;
    _isSearching = false;
    _isCategorizing = null;

    var appSort = Preference.getString(settingsAppSort);
    if (appSort != null) {
      _appSort =
          AppSort.values.firstWhereOrNull((e) => e.toString() == appSort);
    }

    WidgetsBinding.instance.addPostFrameCallback((Duration duration) async {
      var totalApps = await _db.getAppsCount();
      if (totalApps == 0) {
        await _refreshIndicatorKey.currentState!.show();
      } else {
        await _loadApps();
      }
    });
    updatePrefs();
    _initShortcutSupport();
  }

  updatePrefs() {
    setState(() {
      _isDrawerRight = Preference.getBool(settingsDrawerRight);
    });
  }

  _checkCategoryParam() async {
    int? categoryId = await Util.platform.invokeMethod(
        'getParam', <String, dynamic>{'key': 'category_id', 'type': 'int'});
    debugPrint('_checkCategoryParam: ' + categoryId.toString());
    if (categoryId == 0 || categoryId == null && _selectedCategory != null) {
      return; // didn't do anything
    }
    // Reset stuff when it's coming from category shortcut
    Navigator.popUntil(context, ModalRoute.withName('/'));
    if (_isSearching) {
      setState(() {
        _isSearching = false;
      });
    }
    if (isSelecting) {
      _toggleSelecting();
    }

    if (categoryId != null && categoryId > 0 && !Util.isFreeVersion) {
      if (_categories == null) {
        await loadCategories();
      }
      if (_selectedCategory == null || _selectedCategory!.id != categoryId) {
        var category =
            _categories!.where((cat) => cat.id == categoryId).toList();
        await setCategory(category.length > 0 ? category[0] : null);
      }
    } else if (_selectedCategory != null) {
      await setCategory(null);
    }
  }

  void toggleSelectedApp(AppItem? appItem) {
    setState(() {
      appItem!.selected = !appItem.selected;
    });
  }

  List<AppItem> _selectedApps() {
    return _apps!.where((app) => app.selected).toList();
  }

  void onCategorySelected(CategoryItem category) async {
    var selectedApps = _selectedApps();
    await _db.updateAppsCategory(selectedApps, category);
    await loadCategories(force: true);
    await loadSelectedApps();
    _toggleSelecting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _db.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadApps();
    }
    debugPrint('State: ' + state.toString());
  }

  // @override
  // void didUpdateWidget(Widget oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  // }

  void _toggleSelecting() {
    if (isSelecting) {
      _apps!.forEach((app) => app.selected = false);
    }
    setState(() {
      isSelecting = !isSelecting;
    });
  }

  String? appBarTitle() {
    if (_appSort == AppSort.hidden) {
      return 'Hidden apps' +
          (_selectedCategory != null ? ' for ' + _selectedCategory!.name! : '');
    }
    return _selectedCategory != null ? _selectedCategory!.name : widget.title;
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (_scaffoldKey.currentState != null && event.runtimeType.toString() == "RawKeyDownEvent") {
      var orient = MediaQuery.of(context).orientation;
      var maxX = orient == Orientation.portrait ? 4 : 9;
      var maxY = (_apps!.length / maxX).floor() - 1;
      var state = _scaffoldKey.currentState!;
      var key = event.logicalKey.keyLabel;
      if (key == "Arrow Left") {
        if (appLoc[0] <= 0) {
          appLoc[0] = 0;
          state.openDrawer();
        } else {
          appLoc[0]--;
        }
      } else if (key == "Arrow Right") {
        if (appLoc[0] >= maxX) {
          appLoc[0] = maxX;
          state.openEndDrawer();
        } else {
          appLoc[0]++;
        }
      } else if (key == "Arrow Down") {
        if (appLoc[0] == -1)
          appLoc[0] = 0;
        if (appLoc[1] < maxY - 1)
          appLoc[1]++;
      } else if (key == "Arrow Up") {
        if (appLoc[1] > 0)
          appLoc[1]--;
      } else if (key == "Enter" && selectedApp != null) {
        selectedApp!.openApp();
        selectedApp = null;
        appLoc[0] = -1;
        appLoc[1] = 0;
      }
      setState(() {
        appLoc = appLoc;
      });      
    }
  }

  void _showPrivacyAcceptDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Privacy Policy"),
          content: new Text(privacyPolicy),
          actions: <Widget>[
            new TextButton(
              child: new Text("Exit"),
              onPressed: () {
                exit(0);
              },
            ),
            new TextButton(
              child: new Text("Accept"),
              onPressed: () async {
                Navigator.of(context).pop();
                Preference.setBool(settingsPrivacyAccepted, true);
                _refreshIndicatorKey.currentState!.show();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var drawer = AppDrawer(categories: _categories, apps: _apps);
    AppDrawer? leftDrawer = !_isDrawerRight ? drawer : null;
    AppDrawer? rightDrawer = _isDrawerRight ? drawer : null;
    return new WillPopScope(
      onWillPop: () async {
        var allow = true;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
          });
          allow = false;
        } else if (isSelecting) {
          _toggleSelecting();
          allow = false;
        } else if (_appSort == AppSort.hidden) {
          _appSort = AppSort.name;
          await loadCategories(force: true);
          await loadSelectedApps();
          allow = false;
        } else if (_selectedCategory != null) {
          await setCategory(null);
          allow = false;
        }
        return new Future(() => allow);
      },
      child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(appBarTitle()!),
            actions: <Widget>[
              IconButton(
                tooltip: "Select apps",
                icon: Icon(isSelecting ? Icons.clear : Icons.select_all),
                onPressed: () {
                  _toggleSelecting();
                },
              ),
              new PopupMenuButton(
                  icon: Icon(Icons.sort),
                  tooltip: 'Sort apps',
                  itemBuilder: (_) => <PopupMenuItem<String>>[
                        new PopupMenuItem<String>(
                            child: const Text('Name'),
                            value: AppSort.name.toString()),
                        new PopupMenuItem<String>(
                            child: const Text('Recently Installed'),
                            value: AppSort.recentlyInstalled.toString()),
                        new PopupMenuItem<String>(
                            child: const Text('Recently Used'),
                            value: AppSort.recentlyUsed.toString()),
                        new PopupMenuItem<String>(
                            child: const Text('Frequently Used'),
                            value: AppSort.frequentlyUsed.toString()),
                        new PopupMenuItem<String>(
                            child: const Text('Least Used'),
                            value: AppSort.leastUsed.toString()),
                        new PopupMenuItem<String>(
                            child: const Text('Hidden Apps'),
                            value: AppSort.hidden.toString()),
                      ],
                  onSelected: (dynamic val) async {
                    _appSort =
                        AppSort.values.firstWhere((e) => e.toString() == val);
                    if (_appSort != AppSort.hidden) {
                      Preference.setString(settingsAppSort, val);
                    }
                    await loadCategories(force: true);
                    await loadSelectedApps();
                  }),
              isSelecting
                  ? new PopupMenuButton(
                      itemBuilder: (_) => <PopupMenuItem<String>>[
                            new PopupMenuItem<String>(
                                child: const Text('Move to'), value: 'move_to'),
                            new PopupMenuItem<String>(
                                child: const Text('Auto detect category'),
                                value: 'auto_detect_category'),
                            new PopupMenuItem<String>(
                                child: Text(_appSort == AppSort.hidden
                                    ? 'Un-Hide'
                                    : 'Hide'),
                                value: 'hide'),
                          ],
                      onSelected: (dynamic val) async {
                        switch (val) {
                          case 'move_to':
                            var categories = await _db.getCategories(types: [
                              CategoryItem.TYPE_NONE,
                              CategoryItem.TYPE_CUSTOM
                            ]);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategorySelectPage(
                                    categories: categories,
                                    multiSelect: false,
                                    onSelect: onCategorySelected),
                              ),
                            );
                            break;
                          case 'auto_detect_category':
                            _isCategorizing = new Completer<Null>();
                            _refreshIndicatorKey.currentState!.show();
                            var changed =
                                await _db.autoDetectCategory(_selectedApps());
                            if (changed) {
                              await loadCategories(force: true);
                              await loadSelectedApps();
                            }
                            _isCategorizing!.complete();
                            _isCategorizing = null;
                            _toggleSelecting();
                            break;
                          case 'hide':
                            await _db.toggleHideApps(
                                _selectedApps(), _appSort != AppSort.hidden);
                            await loadCategories(force: true);
                            await loadSelectedApps();
                            _toggleSelecting();
                            break;
                        }
                      })
                  : IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    )
            ],
          ),
          drawer: leftDrawer,
          endDrawer: rightDrawer,
          bottomNavigationBar: _isSearching
              ? Transform.translate(
                  offset: Offset(
                      0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
                  child: BottomAppBar(
                    child: Container(
                      margin: EdgeInsets.only(left: 16.0),
                      child: TextField(
                        autofocus: true,
                        onChanged: (text) {
                          setState(() {
                            _searchKey = text;
                          });
                        },
                        decoration: InputDecoration(
                            hintText: 'Search apps',
                            prefixIcon: Icon(
                              Icons.search,
                              size: 28.0,
                            ),
                            suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchKey = '';
                                    _isSearching = false;
                                  });
                                })),
                      ),
                    ),
                  ))
              : null,
          body: RawKeyboardListener(
            onKey: _handleKeyEvent,
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadApps,
              child: AppGrid(
                apps: filteredApps(),
              )), focusNode: _focusNode,autofocus: true,),
          floatingActionButton: Container(
              padding: MediaQuery.of(context).viewInsets.bottom > 0
                  ? EdgeInsets.only(bottom: 42.0)
                  : null,
              child: FloatingActionButton(
                onPressed: () {
                  if (_isSearching) {
                    Util.launchPlayStoreSearch(_searchKey!);
                  } else {
                    setState(() {
                      _isSearching = true;
                    });
                  }
                },
                child: _isSearching
                    ? Container(
                        width: 32,
                        height: 32,
                        child: Image.asset(Util.asset(
                            'assets/app_play_store.png',
                            reverse: false,
                            initial: 'dark',
                            append: 'black')))
                    : Icon(Icons.search),
              ))), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
