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
  String _repeatType = 'None';
  String _selectedSound = 'sound1'; // Default sound

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final existingJournal =
            widget.alarms.firstWhere((element) => element['id'] == widget.id);
        _titleController.text = existingJournal['title'];
        DateTime dateTime = DateTime.parse(existingJournal['dateTime']);
        setState(() {
          date = dateTime;
          time = TimeOfDay.fromDateTime(dateTime);
          _dateController.text = DateFormat('yyyy-MM-dd').format(date!);
          _timeController.text = time!.format(context);
          _repeatType = existingJournal['repeatType'] ?? 'None';
          _selectedSound =
              existingJournal['sound'] ?? 'sound1'; // Initialize selected sound
        });
      });
    } else {
      _titleController.clear();
      date = null;
      time = null;
      _dateController.clear();
      _timeController.clear();
      _selectedSound = 'sound1';
    }
  }

  Future<void> _addItem() async {
    final dateTime =
        DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);

    // Logging start time
    final startTime = DateTime.now();

    final id = await SQLHelper.createItem(
        _titleController.text, dateTime, _repeatType, _selectedSound);
    print('Created new item with id: $id'); // Debug statement

    // Logging time taken for database operation
    print(
        'Database operation took: ${DateTime.now().difference(startTime).inMilliseconds}ms');

    // Scheduling notification
    final notificationStartTime = DateTime.now();
    await AlarmProvider.scheduleNotification(
        id, _titleController.text, dateTime, _repeatType, _selectedSound);

    // Logging time taken for notification scheduling
    print(
        'Notification scheduling took: ${DateTime.now().difference(notificationStartTime).inMilliseconds}ms');

    widget.refreshAlarms();
  }

  Future<void> _updateItem(int id) async {
    final dateTime =
        DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);

    // Logging start time
    final startTime = DateTime.now();

    await SQLHelper.updateItem(
        id, _titleController.text, dateTime, _repeatType, _selectedSound);
    print('Updated item with id: $id'); // Debug statement

    // Logging time taken for database operation
    print(
        'Database operation took: ${DateTime.now().difference(startTime).inMilliseconds}ms');

    // Canceling and rescheduling notification
    final cancelStartTime = DateTime.now();
    await AlarmProvider.cancelNotification(id);
    print(
        'Notification cancelation took: ${DateTime.now().difference(cancelStartTime).inMilliseconds}ms');

    final scheduleStartTime = DateTime.now();
    await AlarmProvider.scheduleNotification(
        id, _titleController.text, dateTime, _repeatType, _selectedSound);
    print(
        'Notification scheduling took: ${DateTime.now().difference(scheduleStartTime).inMilliseconds}ms');

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
      child: SingleChildScrollView(
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
                      _dateController.text =
                          DateFormat('yyyy-MM-dd').format(date!);
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _repeatType,
                decoration: InputDecoration(
                  hintText: 'Repeat Type',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.repeat),
                ),
                items:
                    ['None', 'Daily', 'Weekday', 'Weekend'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _repeatType = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSound,
                decoration: InputDecoration(
                  hintText: 'Alarm Sound',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.music_note),
                ),
                items: [
                  {'value': 'sound1', 'label': 'SMS Sound'},
                  {'value': 'sound2', 'label': 'Bell Sound'},
                  {'value': 'sound3', 'label': 'Marimba Bloop'},
                  {'value': 'sound4', 'label': 'MultiPop'},
                  {'value': 'sound5', 'label': 'Click Sound'},
                ].map((Map<String, String> sound) {
                  return DropdownMenuItem<String>(
                    value: sound['value'],
                    child: Text(sound['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSound = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (widget.id != null) {
                      await _updateItem(widget.id!);
                    } else {
                      await _addItem();
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.id != null ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
