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

  Icon _getRepeatTypeIcon(String repeatType) {
    switch (repeatType) {
      case 'Daily':
        return Icon(Icons.calendar_today, color: Colors.blue, size: 20);
      case 'Weekday':
        return Icon(Icons.work, color: Colors.orange, size: 20);
      case 'Weekend':
        return Icon(Icons.sunny, color: Colors.yellow, size: 20);
      case 'None':
        return Icon(Icons.cancel, color: Colors.grey, size: 20);
      default:
        return Icon(Icons.help, color: Colors.red, size: 20);
    }
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
        elevation: 4,
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
                      final dateTime =
                          DateTime.parse(_alarms[index]['dateTime']);
                      final timeFormatted =
                          DateFormat('HH:mm').format(dateTime);
                      final repeatType = _alarms[index]['repeatType'];

                      return Card(
                        elevation: 5,
                        shadowColor: Colors.grey.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 20,
                                      color: Color.fromARGB(255, 68, 117, 173)),
                                  const SizedBox(width: 10),
                                  Text(
                                    timeFormatted,
                                    style: const TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _getRepeatTypeIcon(repeatType),
                                  const SizedBox(width: 10),
                                  Text(
                                    repeatType,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
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
