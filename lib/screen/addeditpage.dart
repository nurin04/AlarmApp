import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../provider/alarm_provider.dart';
import '../provider/sql_helper.dart';

class ShowForm extends StatefulWidget {
  final int? id;
  final Function refreshAlarms;
  final List<Map<String, dynamic>> alarms;

  const ShowForm({
    Key? key,
    required this.id,
    required this.refreshAlarms,
    required this.alarms,
  }) : super(key: key);

  @override
  _ShowFormState createState() => _ShowFormState();
}

class _ShowFormState extends State<ShowForm> {
  DateTime? date;
  TimeOfDay? time;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final existingJournal = widget.alarms.firstWhere((element) => element['id'] == widget.id);
        _titleController.text = existingJournal['title'];
        DateTime dateTime = DateTime.parse(existingJournal['dateTime']);
        setState(() {
          date = dateTime;
          time = TimeOfDay.fromDateTime(dateTime);
          _dateController.text = DateFormat('yyyy-MM-dd').format(date!);
          _timeController.text = time!.format(context);
        });
      });
    } else {
      _titleController.clear();
      date = null;
      time = null;
      _dateController.clear();
      _timeController.clear();
    }
  }

  Future<void> _addItem() async {
    final dateTime = DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);
    final id = await SQLHelper.createItem(_titleController.text, dateTime);
    print('Created new item with id: $id'); // Debug statement
    await AlarmProvider.scheduleNotification(id, _titleController.text, dateTime);
    widget.refreshAlarms();
  }

  Future<void> _updateItem(int id) async {
    final dateTime = DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);
    await SQLHelper.updateItem(id, _titleController.text, dateTime);
    print('Updated item with id: $id'); // Debug statement
    await AlarmProvider.cancelNotification(id);
    await AlarmProvider.scheduleNotification(id, _titleController.text, dateTime);
    widget.refreshAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 15,
        left: 15,
        right: 15,
        bottom: MediaQuery.of(context).viewInsets.bottom + 120,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                suffixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              readOnly: true,
              controller: _dateController,
              decoration: InputDecoration(
                hintText: 'Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: date ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: Colors.blue,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    date = pickedDate;
                    _dateController.text = DateFormat('yyyy-MM-dd').format(date!);
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please pick a date';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              readOnly: true,
              controller: _timeController,
              decoration: InputDecoration(
                hintText: 'Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: time ?? TimeOfDay.now(),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: Colors.blue,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  setState(() {
                    time = pickedTime;
                    _timeController.text = time!.format(context);
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please pick a time';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() && date != null && time != null) {
                  print('Form is valid, proceeding with save'); // Debug statement
                  if (widget.id == null) {
                    await _addItem();
                  } else {
                    await _updateItem(widget.id!);
                  }

                  _titleController.clear();
                  _dateController.clear();
                  _timeController.clear();
                  date = null;
                  time = null;

                  Navigator.of(context).pop();
                } else {
                  print('Form is not valid or date/time is not set'); // Debug statement
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 13, 60, 114),
              ),
              child: Text(
                widget.id == null ? 'Create New' : 'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
