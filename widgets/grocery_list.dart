import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isloading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'flutter-prep-52531-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);

      // 1. Handle Firebase "null" string or empty body
      if (response.body == 'null' || response.statusCode >= 400) {
        setState(() {
          _isloading = false;
        });
        return;
      }

      if (response.statusCode >= 400) {
        setState(() {
          error = 'Failed to fetch data.Please try again later';
        });
      }
      final Map<String, dynamic> listData = jsonDecode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final entry in listData.entries) {
        // Find the category object based on the title stored in Firebase
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == entry.value['category'],
            )
            .value;

        loadedItems.add(
          GroceryItem(
            id: entry.key,
            name: entry.value['name'],
            quantity: entry.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isloading = false;
      });
    } catch (err) {
      // This catches network issues or parsing errors
      setState(() {
        error = 'Failed to fetch data.Please try again later';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (context) => NewItem()));

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'flutter-prep-52531-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      body: Center(child: Text('You have no items added yet')),
    );

    if (_isloading) {
      content = const Center(child: CircularProgressIndicator());
    } // showing a circular loading sign when coditon is true......

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          background: ColoredBox(color: Colors.redAccent),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    } // displaying this conditional when you have no items added yet

    if (error != null) {
      content = Center(child: Text(error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
