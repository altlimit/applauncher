import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:device_apps/device_apps.dart';
import 'package:applauncher/categories.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle, MethodChannel;
import 'package:package_info/package_info.dart';

const bool isRelease = bool.fromEnvironment("dart.vm.product");
final String apiUrl = isRelease
    ? 'https://altlimit-api.appspot.com/applauncher'
    : 'https://altlimit-api.appspot.com/applauncher';

final String settingsDrawerRight = 'drawer_right';
final String settingsDrawer = 'drawer';
final String settingsDarkMode = 'dark_mode';
final String settingsAppSort = 'app_sort';
final String settingsPrivacyAccepted = 'privacy_accepted';
final String settingsLaunchKey = 'launch_key';

final String miscCategory = '--Misc--';
final String gamesCategory = '--Games--';
final String recentCategory = '--Recent--';
final String frequentCategory = '--Frequent--';

final String tableAppItem = 'app';
final String tableCategory = 'category';
final String tableAppCategory = 'app_category';

final String columnAppItemId = '_id';
final String columnAppItemName = 'name';
final String columnAppItemPackage = 'package';
final String columnAppItemIcon = 'icon';
final String columnAppItemSystem = 'system';
final String columnAppItemLaunchCount = 'launches';
final String columnAppItemHidden = 'hidden';
final String columnAppItemLastLaunch = 'lastlaunch';
final String columnAppItemCategoryId = 'category_id';
final String columnAppItemInstallDate = 'install_date';

final String columnCategoryId = '_id';
final String columnCategoryName = 'name';
final String columnCategoryKey = 'key';
final String columnCategoryInfo = 'info';
final String columnCategoryIcon = 'icon';
final String columnCategoryType = 'type';
final String columnCategoryPinned = 'pinned';
final String columnCategoryHidden = 'hidden';

final String privacyPolicy =
    "Altlimit LLC and its affiliates (collectively 'Altlimit', 'applauncher', 'we' and 'us') takes your privacy seriously. To better protect your privacy we provide this privacy policy notice explaining the way your personal information is collected and used.\n\n"
    "- We will send your personal application list to our server to figure out what category it's in.\n"
    "- We send category  data to our server when you move your application and use it as auto suggested app category to make auto categorization smarter base on your decisions.\n";

final RegExp catRe = new RegExp(r'"/store/apps/category/([^"]+)"]');

// Update categories from
// https://data.42matters.com/api/meta/android/apps/top_chart_categories.json
// JSON.stringify(x.categories.reduce(function (acc, c) { acc[c.cat_key] = c.name; return acc }, {}))

enum AppSort {
  name,
  recentlyInstalled,
  recentlyUsed,
  frequentlyUsed,
  leastUsed,
  hidden
}

abstract class ItemModel {
  int? id;
  Map<String, dynamic> toMap();
}

class AppItem extends ItemModel {
  int? id;
  String? name;
  Uint8List? icon;
  String? package;
  bool? system;
  int? launchCount;
  bool? hidden;
  int? lastLaunch;
  bool selected = false;
  int? categoryId;
  int? installDate;

  AppItem(
      {this.name,
      this.icon,
      this.package,
      this.system,
      this.launchCount,
      this.hidden,
      this.lastLaunch,
      this.categoryId,
      this.installDate});

  openApp() async {
    var success = await DeviceApps.openApp(package!);
    if (success) {
      if (launchCount != null) launchCount = launchCount! + 1;
      lastLaunch = DateTime.now().millisecondsSinceEpoch;
      var dbProvider = DBProvider();
      var db = await dbProvider.open();
      await db.update(
          tableAppItem,
          {
            columnAppItemLastLaunch: lastLaunch,
            columnAppItemLaunchCount: launchCount
          },
          where: '$columnAppItemId = ?',
          whereArgs: [id]);
    }
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnAppItemName: name,
      columnAppItemPackage: package,
      columnAppItemIcon: icon,
      columnAppItemSystem: system! ? 1 : 0,
      columnAppItemLaunchCount: launchCount,
      columnAppItemHidden: hidden! ? 1 : 0,
      columnAppItemLastLaunch: lastLaunch,
      columnAppItemCategoryId: categoryId,
      columnAppItemInstallDate: installDate
    };
    if (id != null) {
      map[columnAppItemId] = id;
    }
    return map;
  }

  AppItem.fromMap(Map<String, dynamic> map) {
    id = map[columnAppItemId];
    name = map[columnAppItemName];
    package = map[columnAppItemPackage];
    icon = map[columnAppItemIcon];
    system = map[columnAppItemSystem] == 1;
    launchCount = map[columnAppItemLaunchCount];
    hidden = map[columnAppItemHidden] == 1;
    lastLaunch = lastLaunch != null ? map[lastLaunch.toString()] : null;
    categoryId = map[columnAppItemCategoryId];
    installDate = map[columnAppItemInstallDate];
  }
}

class CategoryItem extends ItemModel {
  static const int TYPE_NONE = 0;
  static const int TYPE_MIXED = 1;
  static const int TYPE_PACKAGE = 2;
  static const int TYPE_CUSTOM = 3;

  int? id;
  String? name;
  Uint8List? icon;
  String? key;
  String? info;
  int? type;
  int? appCount;
  bool? pinned;
  bool? hidden;

  CategoryItem(
      {this.name,
      this.key,
      this.icon,
      this.info,
      this.type,
      this.pinned,
      this.hidden});

  String getIconKey(String? customKey) {
    if (customKey == null && icon != null) {
      try {
        var iconKey = utf8.decode(List.from(icon!));
        customKey = iconKey.substring(5);
      } on Exception catch (_) {}
    }
    if (customKey == null) customKey = key;
    if (customKey != null && customKey == '') customKey = 'misc';
    return Util.asset(
        'category_' + customKey!.replaceAll('--', '').toLowerCase());
  }

  Image getImage(double? width) {
    return Image.asset(
      'assets/' + getIconKey(id == null ? 'misc' : null) + '.png',
      width: width,
    );
  }

  Future<Uint8List?> getIconBytes() async {
    if (icon != null) {
      return icon;
    }
    var bytes = await rootBundle.load('assets/' + getIconKey(null) + '.png');
    return bytes.buffer.asUint8List();
  }

  bool isBuiltIn() {
    return type == CategoryItem.TYPE_NONE ||
        [miscCategory, gamesCategory, frequentCategory, recentCategory]
            .contains(key);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnCategoryName: name,
      columnCategoryKey: key,
      columnCategoryIcon: icon,
      columnCategoryInfo: info,
      columnCategoryType: type,
      columnCategoryPinned: pinned! ? 1 : 0,
      columnCategoryHidden: hidden! ? 1 : 0,
    };
    if (id != null) {
      map[columnCategoryId] = id;
    }
    return map;
  }

  CategoryItem.fromMap(Map<String, dynamic> map) {
    id = map[columnCategoryId];
    name = map[columnCategoryName];
    key = map[columnCategoryKey];
    icon = map[columnCategoryIcon];
    info = map[columnCategoryInfo];
    type = map[columnCategoryType];
    pinned = map[columnCategoryPinned] == 1;
    hidden = map[columnCategoryHidden] == 1;
    if (map.containsKey('app_count')) {
      appCount = map['app_count'];
    }
  }

  togglePin() async {
    var dbProvider = DBProvider();
    var db = await dbProvider.open();
    pinned = !pinned!;
    await db.update(
        tableCategory,
        {
          columnCategoryPinned: pinned! ? 1 : 0,
        },
        where: '$columnCategoryId = ?',
        whereArgs: [id]);
  }
}

class DBProvider {
  static final DBProvider _instance = new DBProvider.internal();

  factory DBProvider() => _instance;
  DBProvider.internal();

  static Database? _db;

  createDB(Batch batch) async {
    batch.execute("""
          CREATE TABLE $tableAppItem (
            $columnAppItemId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnAppItemName TEXT,
            $columnAppItemPackage TEXT,
            $columnAppItemIcon BLOB,
            $columnAppItemLaunchCount INTEGER,
            $columnAppItemHidden INTEGER,
            $columnAppItemLastLaunch INTEGER,
            $columnAppItemSystem INTEGER,
            $columnAppItemCategoryId INTEGER,
            $columnAppItemInstallDate INTEGER,
            CONSTRAINT unique_package UNIQUE ($columnAppItemPackage)
          )""");
    batch.execute("""
            CREATE TABLE $tableCategory (
              $columnCategoryId INTEGER PRIMARY KEY AUTOINCREMENT,
              $columnCategoryName TEXT,
              $columnCategoryKey TEXT,
              $columnCategoryInfo TEXT,
              $columnCategoryType INTEGER,
              $columnCategoryPinned INTEGER,
              $columnCategoryHidden INTEGER,
              $columnCategoryIcon BLOB,
              CONSTRAINT unique_key UNIQUE ($columnCategoryKey)
            )""");
    await batch.commit();
  }

  Future<Database> open() async {
    if (_db == null) {
      var path = await getDatabasesPath();

      var dbPath = p.join(path, 'apps.db');
      if (!isRelease) {
        // await deleteDatabase(path);
      }
      _db = await openDatabase(dbPath, version: 4,
          onCreate: (Database db, int version) async {
        await createDB(db.batch());
      }, onUpgrade: (Database db, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          var batch = db.batch();
          batch.execute('DROP TABLE IF EXISTS $tableAppCategory');
          batch.execute('DROP TABLE IF EXISTS $tableCategory');
          batch.execute('DROP TABLE IF EXISTS $tableAppItem');
          await createDB(batch);
        } else if (oldVersion == 2) {
          var rmCats = "'" + removedCategories.keys.join("','") + "'";
          var rows = await db.rawQuery(
              "SELECT $columnCategoryId FROM $tableCategory WHERE $columnCategoryKey = '" +
                  miscCategory +
                  "'");
          int? miscCatId = rows[0][columnCategoryId] as int?;
          var batch = db.batch();
          batch.update(tableAppItem, {columnAppItemCategoryId: miscCatId},
              where:
                  '$columnAppItemCategoryId IN (SELECT $columnCategoryId FROM $tableCategory WHERE $columnCategoryKey IN ($rmCats))');
          batch.execute(
              'DELETE FROM $tableCategory WHERE $columnCategoryKey IN ($rmCats)');
          batch.execute(
              'ALTER TABLE $tableAppItem ADD COLUMN $columnAppItemInstallDate INTEGER');
          await batch.commit();
        } else if (oldVersion == 3) {
          await db.execute(
              'ALTER TABLE $tableCategory ADD COLUMN $columnCategoryHidden INTEGER');
        }
      });
    }
    return _db!;
  }

  Future clearDB() async {
    var db = await open();
    var batch = db.batch();
    batch.rawDelete('DELETE FROM $tableAppItem');
    batch.rawDelete('DELETE FROM $tableCategory');
    batch.rawDelete("DELETE FROM SQLITE_SEQUENCE WHERE name='$tableAppItem'");
    batch.rawDelete("DELETE FROM SQLITE_SEQUENCE WHERE name='$tableCategory'");
    await batch.commit();
    await Util.platform.invokeMethod('deleteAllShortcuts');
  }

  Future<AppItem?> getAppItem(String package) async {
    var db = await open();
    List<Map<String, Object?>>? maps = await db.query(tableAppItem,
        columns: [
          columnAppItemId,
          columnAppItemName,
          columnAppItemPackage,
          columnAppItemIcon
        ],
        where: '$columnAppItemPackage = ?',
        whereArgs: [package]);
    if (maps.length > 0) {
      return AppItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> getAppsCount() async {
    var db = await open();
    var rows = await db.rawQuery(
        'SELECT COUNT($columnAppItemId) as totalApps FROM $tableAppItem');
    return rows[0]['totalApps'] as int;
  }

  Future hideCategories(List<CategoryItem> categories) async {
    var db = await open();
    var batch = db.batch();
    var catIds = categories.map((c) => c.id.toString()).join(',');
    batch.update(tableCategory, {columnCategoryHidden: 0},
        where: '$columnCategoryHidden = 1');
    if (catIds.length > 0) {
      batch.update(tableCategory, {columnCategoryHidden: 1},
          where: '$columnCategoryId IN ($catIds)');
    }
    await batch.commit();
  }

  Future toggleHideApps(List<AppItem> apps, bool hide) async {
    var db = await open();
    var appIds = apps.map((c) => c.id.toString()).join(',');
    if (appIds.length > 0) {
      await db.update(tableAppItem, {columnAppItemHidden: hide ? 1 : 0},
          where: '$columnAppItemId IN ($appIds)');
    }
  }

  Future<List<AppItem>> getApps(CategoryItem? category, {AppSort? sort}) async {
    var db = await open();
    var where = List<String>.empty(growable: true);
    var hidden = sort == AppSort.hidden ? 1 : 0;
    var sql =
        'SELECT * FROM $tableAppItem WHERE $columnAppItemHidden = $hidden';
    if (category != null) {
      if (category.type == CategoryItem.TYPE_MIXED &&
          category.key != miscCategory) {
        if (category.key == recentCategory) {
          sql += ' AND $columnAppItemLastLaunch > 0';
        } else if (category.key == frequentCategory) {
          sql += ' AND $columnAppItemLaunchCount > 0';
        } else {
          if (category.info!.length > 0) {
            where.add('$columnCategoryKey IN (' +
                "'" +
                category.info!.split(",").join("','") +
                "')");
          }
          if (category.key == gamesCategory) {
            where.add("$columnCategoryKey LIKE '%GAME%'");
          }
          var whereClause =
              where.length > 0 ? ' WHERE ' + where.join(' OR ') : '';
          sql += """
            AND $columnAppItemCategoryId IN (
              SELECT DISTINCT $columnCategoryId
              FROM $tableCategory
              $whereClause
            )
          """;
        }
      } else if (category.type == CategoryItem.TYPE_PACKAGE &&
          category.info!.length > 0) {
        category.info!.split(',').forEach((package) {
          where.add("$columnAppItemPackage LIKE '%$package%'");
        });
        sql += ' AND (' + where.join(' OR ') + ')';
      } else {
        sql += ' AND $columnAppItemCategoryId = ${category.id}';
      }
    }
    if (category != null && category.key == recentCategory) {
      sql +=
          ' ORDER BY $columnAppItemLastLaunch DESC,$columnAppItemName COLLATE NOCASE';
    } else if (category != null && category.key == frequentCategory) {
      sql +=
          ' ORDER BY $columnAppItemLaunchCount DESC,$columnAppItemName COLLATE NOCASE';
    } else {
      if (sort == AppSort.recentlyInstalled) {
        sql +=
            ' ORDER BY $columnAppItemInstallDate DESC,$columnAppItemName COLLATE NOCASE';
      } else if (sort == AppSort.recentlyUsed) {
        sql +=
            ' ORDER BY $columnAppItemLastLaunch DESC,$columnAppItemName COLLATE NOCASE';
      } else if (sort == AppSort.frequentlyUsed) {
        sql +=
            ' ORDER BY $columnAppItemLaunchCount DESC,$columnAppItemName COLLATE NOCASE';
      } else if (sort == AppSort.leastUsed) {
        sql +=
            ' ORDER BY $columnAppItemLaunchCount,$columnAppItemLaunchCount,$columnAppItemName COLLATE NOCASE';
      } else {
        sql += ' ORDER BY $columnAppItemName COLLATE NOCASE';
      }
    }
    List<Map>? rows = await db.rawQuery(sql);
    return rows
        .map((row) => AppItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppItem>> getAppsBy({List<int?>? ids, int? limit}) async {
    var db = await open();
    var sql = 'SELECT * FROM $tableAppItem';

    if (ids != null) {
      var filter = "'" + ids.join("','") + "'";
      sql += ' WHERE $columnAppItemId IN ($filter)';
    }
    if (limit != null) {
      sql += ' LIMIT ' + limit.toString();
    }
    sql += ' ORDER BY $columnAppItemName COLLATE NOCASE';
    List<Map> rows = await db.rawQuery(sql);
    return rows
        .map((row) => AppItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryItem>> getCategories(
      {List<int>? types,
      List<String>? keys,
      bool? all,
      bool hidden = false}) async {
    var db = await open();
    var sql = '';
    if (keys != null) {
      var keysSql = "'" + keys.join("','") + "'";
      sql =
          'SELECT * FROM $tableCategory WHERE $columnCategoryKey IN ($keysSql) ORDER BY $columnCategoryName COLLATE NOCASE';
    } else if (types != null) {
      var typeSql = types.join(',');
      sql =
          'SELECT * FROM $tableCategory WHERE $columnCategoryType IN ($typeSql) ORDER BY $columnCategoryName COLLATE NOCASE';
    } else if (all == true) {
      sql =
          'SELECT * FROM $tableCategory ORDER BY $columnCategoryName COLLATE NOCASE';
    } else {
      var h = hidden ? 1 : 0;
      sql = """
      SELECT c.*,COUNT(ai.$columnAppItemId) AS app_count FROM $tableCategory AS c
      LEFT OUTER JOIN $tableAppItem AS ai ON ai.$columnAppItemCategoryId = c.$columnCategoryId AND ai.$columnAppItemHidden = $h
      GROUP BY c.$columnCategoryId
      HAVING app_count > 0 OR c.$columnCategoryType > 0
      ORDER BY c.$columnCategoryPinned DESC,c.$columnCategoryName COLLATE NOCASE
      """;
    }

    List<Map> rows = await db.rawQuery(sql);
    return rows
        .map((row) => CategoryItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  upsertCategories(Map<String, List<dynamic>> sourceCategories,
      Map<String?, CategoryItem> cats, Batch batch, int catType) {
    sourceCategories.forEach((k, v) {
      var cKey = '--' + k + '--';
      var info = v.join(',');
      var cType = catType;
      if (cKey == miscCategory) {
        cType = CategoryItem.TYPE_NONE;
      }
      if (!cats.containsKey(cKey)) {
        batch.insert(
            tableCategory,
            CategoryItem(
                    name: k,
                    key: cKey,
                    pinned: false,
                    hidden: false,
                    type: cType,
                    info: info)
                .toMap());
      } else if (cats[cKey]!.info != info || cats[cKey]!.type != cType) {
        batch.update(tableCategory,
            {columnCategoryInfo: info, columnCategoryType: cType},
            where: '$columnCategoryId = ?', whereArgs: [cats[cKey]!.id]);
      }
    });
  }

  saveCategory(CategoryItem category) async {
    var db = await open();
    if (category.key == "") category.key = "custom_" + category.name!;
    if (category.id == null) {
      await db.insert(tableCategory, category.toMap());
    } else {
      await db.update(
          tableCategory,
          {
            columnCategoryKey: category.key,
            columnCategoryInfo: category.info,
            columnCategoryType: category.type,
            columnCategoryName: category.name,
            columnCategoryIcon: category.icon,
          },
          where: '$columnCategoryId = ?',
          whereArgs: [category.id]);
    }
  }

  deleteCategory(int categoryId) async {
    var db = await open();
    await db.delete(tableCategory,
        where: '$columnCategoryId = ?', whereArgs: [categoryId]);
  }

  updateAppsCategory(List<AppItem> apps, CategoryItem category) async {
    var db = await open();
    // filter apps that's already in that category
    apps = apps.where((app) => app.categoryId != category.id).toList();
    var appIds = apps.map((app) => app.id).join(',');
    await db.update(tableAppItem, {columnAppItemCategoryId: category.id},
        where: '$columnAppItemId IN ($appIds)');

    apps.forEach((app) {
      app.categoryId = category.id;
    });

    if (category.type == CategoryItem.TYPE_NONE)
      http.post(Uri.parse(apiUrl + '/suggest'), body: {
        'apps': apps.map((app) => app.package).join(','),
        'category': category.key,
      });
  }

  Future<bool> autoDetectCategory(List<AppItem> apps) async {
    var appsMap = new Map<String, List<AppItem>>();
    var futures = apps.map((app) async {
      var category = await Util.requestPlayStoreCategory(app.package!);
      if (category.length > 0) {
        if (!appsMap.containsKey(category)) {
          appsMap[category] = new List<AppItem>.empty(growable: true);
        }
        appsMap[category]!.add(app);
      }
    });
    await Future.wait(futures);
    if (appsMap.length > 0) {
      var categories = await getCategories(keys: appsMap.keys.toList());
      var categoryMap = new Map<String?, CategoryItem>();
      categories.forEach((c) {
        categoryMap[c.key] = c;
      });

      for (var key in appsMap.keys) {
        await updateAppsCategory(appsMap[key]!, categoryMap[key]!);
      }
      return true;
    }
    return false;
  }

  loadApps() async {
    var db = await open();
    var hasChanged = false;
    var packages = Map<String?, int?>();
    var cats = Map<String?, CategoryItem>();

    var rows = await db.rawQuery(
        'SELECT $columnAppItemId,$columnAppItemPackage FROM $tableAppItem');
    var initialImport = rows.length == 0;

    rows.forEach((row) {
      packages[row[columnAppItemPackage] as String] =
          row[columnAppItemId] as int?;
    });

    rows = await db.rawQuery('SELECT * FROM $tableCategory');
    rows.forEach((row) {
      cats[row[columnCategoryKey] as String] = CategoryItem.fromMap(row);
    });

    var apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: true,
        includeAppIcons: initialImport);

    var batch = db.batch();
    // load up all categories that does not exists
    categoriesMap.forEach((k, v) {
      if (!cats.containsKey(k)) {
        batch.insert(
            tableCategory,
            CategoryItem(
                    name: v,
                    key: k,
                    type: CategoryItem.TYPE_NONE,
                    pinned: false,
                    hidden: false)
                .toMap());
      }
    });

    // Update or insert built-in categories
    upsertCategories(mixedCategories, cats, batch, CategoryItem.TYPE_MIXED);
    upsertCategories(packageCategories, cats, batch, CategoryItem.TYPE_PACKAGE);
    if (!initialImport)
      await batch.commit(noResult: false);

    apps.forEach((app) async {
      if (packages.containsKey(app.packageName)) {
        // clear found package so we can delete uninstalled later
        packages.remove(app.packageName);
      } else {
        // add not found in db but installed
        hasChanged = true;
        ApplicationWithIcon? appIcon;
        if (!initialImport) {
          var newApp = await DeviceApps.getApp(app.packageName, true);
          app = newApp!;
        }
        appIcon = app as ApplicationWithIcon?;
        var appItem = AppItem(
            name: appIcon!.appName,
            icon: appIcon.icon,
            package: appIcon.packageName,
            system: appIcon.systemApp,
            installDate: DateTime.now().millisecondsSinceEpoch,
            hidden: false,
            launchCount: 0,
            lastLaunch: 0);
        if (initialImport)
          batch.insert(tableAppItem, appItem.toMap());
        else
          await db.insert(tableAppItem, appItem.toMap());
      }
    });
    if (initialImport)
      await batch.commit(noResult: false);

    if (packages.length > 0) {
      // some apps have been uninstalled let's delete it from database
      hasChanged = true;
      var packageIds = "'" + packages.keys.join("','") + "'";
      await db.rawDelete(
          'DELETE FROM $tableAppItem WHERE $columnAppItemPackage IN ($packageIds)');
      packages.clear();
    }

    // Get all apps with category_id NULL
    rows = await db.rawQuery("""
    SELECT $columnAppItemId,$columnAppItemPackage FROM $tableAppItem
      WHERE $columnAppItemCategoryId IS NULL or $columnAppItemCategoryId = ''
    """);
    if (rows.length > 0) {
      // Get missing packages category
      rows.forEach((row) {
        packages[row[columnAppItemPackage] as String] =
            row[columnAppItemId] as int?;
      });
      var response = await http.post(Uri.parse(apiUrl + '/import'),
          body: {'apps': packages.keys.join(',')});
      if (response.statusCode == 200) {
        Map<String, dynamic> pInfo = json.decode(response.body);
        var foundPackages = "'" + pInfo.values.join("','") + "'";
        rows = await db.rawQuery("""
          SELECT $columnCategoryId,$columnCategoryKey FROM $tableCategory
          WHERE $columnCategoryKey IN ($foundPackages) OR $columnCategoryKey LIKE '--%--'
          """);
        var packageMap = Map<String?, int?>();
        rows.forEach((row) {
          packageMap[row[columnCategoryKey] as String] =
              row[columnCategoryId] as int?;
        });
        var batch = db.batch();
        var miscAppIds = new List<int?>.empty(growable: true);
        packages.forEach((k, v) {
          var isMisc = !pInfo.containsKey(k);
          if (isMisc) {
            miscAppIds.add(v);
          }
          batch.update(
              tableAppItem,
              {
                columnAppItemCategoryId:
                    packageMap[isMisc ? miscCategory : pInfo[k!]],
              },
              where: '$columnAppItemId = ?',
              whereArgs: [v]);
        });
        await batch.commit();
        // Now process misc category locally see if we see any better results
        if (miscAppIds.length > 0) {
          var miscApps = await getAppsBy(ids: miscAppIds);
          await autoDetectCategory(miscApps);
        }
      }
    }

    return hasChanged;
  }

  Future close() async => _db!.close();
}

class Util {
  static late PackageInfo packageInfo;
  static late MethodChannel platform;
  static late bool isFreeVersion;

  static Future init() async {
    packageInfo = await PackageInfo.fromPlatform();
    isFreeVersion = packageInfo.packageName == 'com.altlimit.applauncherfree';
    platform = MethodChannel(packageInfo.packageName);
  }

  static String getCategoryType(int id) {
    switch (id) {
      case CategoryItem.TYPE_CUSTOM:
        return "Custom";
      case CategoryItem.TYPE_MIXED:
        return "Grouped Category";
      case CategoryItem.TYPE_PACKAGE:
        return "Filtered Package";
    }
    return "";
  }

  static String asset(String path,
      {bool reverse = false, String append = 'dark', String? initial}) {
    var isDarkMode = Preference.getBool(settingsDarkMode);
    if (reverse) {
      isDarkMode = !isDarkMode;
    }
    if (initial != null && !isDarkMode) {
      isDarkMode = true;
      append = initial;
    }
    if (isDarkMode) {
      if (path.endsWith('.png')) {
        path = path.replaceFirst('.png', '_$append.png');
      } else {
        path += '_$append';
      }
    }
    return path;
  }

  static Future launchUri(String uri) async {
    if (await canLaunch(uri)) {
      await launch(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }

  static void launchPremium() async {
    await launchPlayStore('com.altlimit.applauncherplus');
  }

  static Future launchAbout() async {
    await launchUri('https://github.com/altlimit/applauncher');
  }

  static Future launchPlayStore(String package) async {
    await launchUri('https://play.google.com/store/apps/details?id=' + package);
  }

  static void launchPlayStoreSearch(String q) async {
    await launchUri('https://play.google.com/store/search?q=' + q);
  }

  static Future launchEmailSupport() async {
    var subject = Util.isFreeVersion ? 'AppLaucnher+ Free' : 'AppLauncher+';
    await launchUri('mailto:support@altlimit.com?subject=$subject');
  }

  static Future<String> requestPlayStoreCategory(String package) async {
    print('Fetching ' + package + ' from play store...');
    var response = await http.get(
        Uri.parse('https://play.google.com/store/apps/details?id=' + package),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'
        });
    if (response.statusCode == 404) {
      print('Fetching ' + package + ' from suggested...');
      response = await http
          .post(Uri.parse(apiUrl + '/import'), body: {'apps': package});
      if (response.statusCode == 200) {
        Map<String, dynamic> pInfo = json.decode(response.body);
        if (pInfo.length > 0 && pInfo.containsKey(package)) {
          print('Found from suggested ' + pInfo[package]!);
          return pInfo[package]!;
        }
      }
    } else if (response.statusCode == 200) {
      String body = response.body;
      if (body.contains('<title>Not Found</title>')) {
        print('not found');
        return "";
      }

      var matches = catRe.allMatches(body);
      if (matches.length < 2) {
        return "";
      }

      var cat = matches.elementAt(1).group(1).toString();
      if (categoriesMap.containsKey(cat)) {
        print('Found ' + cat);
        return cat;
      }
    }
    print('Not found');
    return "";
  }
}

class Preference {
  static SharedPreferences? _prefs;
  static Map<String, dynamic> _memoryPrefs = Map<String, dynamic>();

  static Future<SharedPreferences?> load() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs;
  }

  static void setString(String key, String value) {
    _prefs!.setString(key, value);
    _memoryPrefs[key] = value;
  }

  static void setInt(String key, int value) {
    _prefs!.setInt(key, value);
    _memoryPrefs[key] = value;
  }

  static void setDouble(String key, double value) {
    _prefs!.setDouble(key, value);
    _memoryPrefs[key] = value;
  }

  static void setBool(String key, bool value) {
    _prefs!.setBool(key, value);
    _memoryPrefs[key] = value;
  }

  static String? getString(String key, {String? def}) {
    String? val;
    if (_memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    }
    if (val == null) {
      val = _prefs!.getString(key);
    }
    _memoryPrefs[key] = val;
    return val;
  }

  static int? getInt(String key, {int? def}) {
    int? val;
    if (_memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    }
    if (val == null) {
      val = _prefs!.getInt(key);
    }
    _memoryPrefs[key] = val;
    return val;
  }

  static double? getDouble(String key, {double? def}) {
    double? val;
    if (_memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    }
    if (val == null) {
      val = _prefs!.getDouble(key);
    }
    _memoryPrefs[key] = val;
    return val;
  }

  static bool getBool(String key, {bool def = false}) {
    bool? val;
    if (_memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    }
    if (val == null) {
      val = _prefs!.getBool(key);
    }
    _memoryPrefs[key] = val;
    return val == null ? false : val;
  }
}

class DrawerPref {
  Map<String, dynamic>? _config;

  load(SharedPreferences prefs) {
    var config = prefs.getString(settingsDrawer);
    if (config != null) {
      _config = json.decode(config);
    } else {
      _config = Map<String, dynamic>();
    }
  }

  save(SharedPreferences prefs) {
    prefs.setString(settingsDrawer, json.encode(_config));
  }

  hasValue(String key) {
    return _config != null &&
        _config!.containsKey(key) &&
        _config![key] != null;
  }

  double? getDouble(String key, double def) {
    return hasValue(key) ? _config![key] : def;
  }

  int? getInt(String key, int def) {
    return hasValue(key) ? _config![key] : def;
  }
}
