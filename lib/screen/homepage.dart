//hello

import 'dart:async';

import 'package:crud_alarm/provider/uiprovider.dart';
import 'package:crud_alarm/screen/popupmenu.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/alarm_provider.dart';
import '../provider/sql_helper.dart';
import 'addeditpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _alarms = [];
  bool _isLoading = true;

  void _refreshAlarms() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _alarms = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
    _refreshAlarms();
  }

  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    await AlarmProvider.cancelNotification(id);
    print('Deleted item with id: $id');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully deleted an alarm!'),
      ),
    );
    _refreshAlarms();
  }

  void _showForm(int? id) {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => ShowForm(
        id: id,
        refreshAlarms: _refreshAlarms,
        alarms: _alarms,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AlarmBuddy',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 13, 60, 114),
        actions: [
          Consumer<UiProvider>(
            builder: (context, UiProvider notifier, child) {
              return IconButton(
                icon: Icon(
                  notifier.isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  notifier.changeTheme();
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                DateFormat.yMEd().add_jms().format(DateTime.now()),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) {
                      final title = _alarms[index]['title'];
                      final dateTime = DateTime.parse(_alarms[index]['dateTime']);
                      final dateFormatted = DateFormat('yyyy-MM-dd').format(dateTime);
                      final timeFormatted = DateFormat('HH:mm').format(dateTime);

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.all(15),
                        child: ListTile(
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Color.fromARGB(255, 68, 117, 173)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$dateFormatted',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: Color.fromARGB(255, 68, 117, 173)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$timeFormatted',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                          trailing: PopupMenu(
                            onSelected: (int value) {
                              if (value == 0) {
                                _showForm(_alarms[index]['id']);
                              } else if (value == 1) {
                                _deleteItem(_alarms[index]['id']);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 13, 60, 114),
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
