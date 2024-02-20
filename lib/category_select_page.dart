import 'package:flutter/material.dart';
import 'package:applauncher/app_model.dart';

class CategorySelectPage extends StatefulWidget {
  final List<CategoryItem>? categories;
  final Function? onSelect;
  final bool? multiSelect;
  final List<CategoryItem>? selected;

  CategorySelectPage(
      {this.categories, this.onSelect, this.multiSelect, this.selected});

  @override
  _CategorySelectState createState() => _CategorySelectState();
}

class _CategorySelectState extends State<CategorySelectPage> {
  List<CategoryItem>? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected == null
        ? List<CategoryItem>.empty(growable: true)
        : widget.selected;
    print('Selected: ' + _selected!.length.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: <Widget>[
      Expanded(
          child: ListView.builder(
        itemCount: widget.categories!.length,
        itemBuilder: (context, index) {
          var c = widget.categories![index];
          return ListTile(
            leading:
                new Container(width: 24, height: 24, child: c.getImage(null)),
            title: Text(c.name!),
            subtitle:
                Text(c.key!.toUpperCase().contains('GAME') ? 'Games' : 'Apps'),
            onTap: () {
              setState(() {
                if (widget.multiSelect!) {
                  if (_selected!.contains(c)) {
                    _selected!.remove(c);
                  } else {
                    _selected!.add(c);
                  }
                } else {
                  _selected!.clear();
                  _selected!.add(c);
                }
              });
            },
            trailing: _selected!.contains(c) ? Icon(Icons.check_circle) : null,
          );
        },
      )),
      Row(children: <Widget>[
        Expanded(
          child: MaterialButton(
            child: Text("Cancel"),
            onPressed: () {
              _selected!.clear();
              Navigator.of(context).pop();
            },
          ),
        ),
        Expanded(
          child: MaterialButton(
            child: Text("OK"),
            onPressed: _selected!.length == 0 && !widget.multiSelect!
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onSelect!(
                        widget.multiSelect! ? _selected : _selected![0]);
                  },
          ),
        ),
      ])
    ]));
  }
}
