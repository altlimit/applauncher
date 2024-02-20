import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:applauncher/app_model.dart';
import 'package:applauncher/category_select_page.dart';
import 'package:applauncher/store.dart';

class CategoryEditPage extends StatefulWidget {
  final CategoryItem? category;
  final List<CategoryItem>? allCategories;

  CategoryEditPage({this.category, this.allCategories});

  @override
  _CategoryEditState createState() => _CategoryEditState();
}

class _CategoryEditState extends State<CategoryEditPage> with Store {
  final DBProvider _db = DBProvider();
  CategoryItem _category = new CategoryItem();
  List<CategoryItem> _allCategories = new List<CategoryItem>.empty();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _category = CategoryItem.fromMap(widget.category!.toMap());
    }
    _allCategories = widget.allCategories!;
  }

  List<CategoryItem> getInfoCategories() {
    if (_category.info!.length == 0) return List<CategoryItem>.empty();
    var cats = _category.info!.split(',');
    return _allCategories.where((c) => cats.contains(c.key)).toList();
  }

  @override
  Widget build(BuildContext context) {
    var widgetChildren = <Widget>[
      TextFormField(
        initialValue: _category.name!,
        maxLength: 50,
        onChanged: (v) {
          setState(() {
            _category.name = v;
          });
        },
        decoration: InputDecoration(
          icon: _category.getImage(50),
          labelText: 'Category Name',
        ),
      ),
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySelectPage(
                  categories: _allCategories
                      .where((c) => !c.key!.startsWith('custom_'))
                      .toList(),
                  multiSelect: false,
                  onSelect: (selected) async {
                    var category = selected as CategoryItem;
                    setState(() {
                      _category.icon = Uint8List.fromList(
                          utf8.encode('icon:' + category.key!));
                    });
                  }),
            ),
          );
        },
        child: Text('Update Icon'),
      ),
      DropdownButton<int>(
        isExpanded: true,
        items: <int>[
          CategoryItem.TYPE_MIXED,
          CategoryItem.TYPE_PACKAGE,
          CategoryItem.TYPE_CUSTOM,
        ].map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: new Text(Util.getCategoryType(value)),
          );
        }).toList(),
        value: _category.type,
        onChanged: (value) {
          print("Value" + value!.toString());
          setState(() {
            _category.type = value;
            _category.info = "";
          });
        },
      )
    ];
    if (_category.type == CategoryItem.TYPE_MIXED) {
      widgetChildren.add(TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySelectPage(
                  categories: _allCategories,
                  selected: List<CategoryItem>.from(getInfoCategories()),
                  multiSelect: true,
                  onSelect: (selected) async {
                    var categories = selected as List<CategoryItem>;
                    setState(() {
                      _category.info = categories.map((c) => c.key).join(',');
                    });
                  }),
            ),
          );
        },
        child: Text('Change Categories'),
      ));
      var categories = getInfoCategories();

      widgetChildren.add(Expanded(
          child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          var c = categories[index];
          return ListTile(
              leading:
                  new Container(width: 24, height: 24, child: c.getImage(null)),
              title: Text(c.name!));
        },
      )));
    } else if (_category.type == CategoryItem.TYPE_PACKAGE) {
      widgetChildren.add(TextFormField(
        initialValue: _category.info,
        onChanged: (v) {
          setState(() {
            _category.info = v;
          });
        },
        decoration: InputDecoration(
            labelText: 'Package Filter',
            helperText: 'Comma separated package names'),
      ));
    }
    if (_category.id != null)
      widgetChildren.add(TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context2) {
              return AlertDialog(
                title: new Text("Delete '" + _category.name! + "' category"),
                content: new Text("Are you sure?"),
                actions: <Widget>[
                  new TextButton(
                    child: new Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context2).pop();
                    },
                  ),
                  new TextButton(
                    child: new Text("Delete"),
                    onPressed: () async {
                      await _db.deleteCategory(_category.id!);
                      await appDrawerState!.loadCategories(force: true);
                      Navigator.of(context2).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Text('Delete Category'),
      ));
    return Scaffold(
        appBar: AppBar(
          title: Text(_category.name!),
        ),
        body: Container(
            margin: EdgeInsets.all(20),
            child: Column(children: <Widget>[
              Expanded(
                  child: Column(
                children: widgetChildren,
              )),
              Row(children: <Widget>[
                Expanded(
                  child: MaterialButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: MaterialButton(
                    child: Text("Save"),
                    onPressed: _category.name != null &&
                            _category.name!.length > 0
                        ? () async {
                            FocusScope.of(context).unfocus();
                            await _db.saveCategory(_category);
                            await appDrawerState!.loadCategories(force: true);
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ),
              ])
            ])));
  }
}
