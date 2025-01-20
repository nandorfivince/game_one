import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ToggleButtonScreen(),
    );
  }
}

class ToggleButtonScreen extends StatefulWidget {
  @override
  _ToggleButtonScreenState createState() => _ToggleButtonScreenState();
}

class _ToggleButtonScreenState extends State<ToggleButtonScreen> {
  bool isDone = false;
  String? lastDoneTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    await _loadState();
    if (await _isNewDay()) {
      _resetState(preserveTimestamp: true);
    }
    _scheduleMidnightReset();
  }

  Future<void> _saveState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDone', state);
    if (state) {
      final now = DateTime.now();
      String timestamp = _formatDateTime(now);

      // Mentés a listába
      List<String> logList = prefs.getStringList('logList') ?? [];
      logList.add(timestamp);
      await prefs.setStringList('logList', logList);

      prefs.setString('lastDoneTime', timestamp);
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getBool('isDone') ?? false;
    final savedLastDoneTime = prefs.getString('lastDoneTime');

    setState(() {
      isDone = savedState;
      lastDoneTime = savedLastDoneTime;
    });
  }

  Future<bool> _isNewDay() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    final lastCheck = prefs.getString('lastCheckDate') ?? '';
    final today = "${now.year}-${now.month}-${now.day}";

    if (lastCheck != today) {
      await prefs.setString('lastCheckDate', today);
      return true;
    }
    return false;
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 0);
    final durationUntilMidnight = midnight.difference(now);

    _timer?.cancel();
    _timer = Timer(durationUntilMidnight, () {
      _resetState(preserveTimestamp: true);
      _scheduleMidnightReset();
    });
  }

  void _resetState({bool preserveTimestamp = false}) {
    setState(() {
      isDone = false;
      if (!preserveTimestamp) {
        lastDoneTime = null;
      }
    });
    _saveState(false);
  }

  Future<void> _clearTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastDoneTime');
    setState(() {
      lastDoneTime = null;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bevettem a gyógyszert?'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lastDoneTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  "Legutóbb bevetted: $lastDoneTime",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isDone = true;
                  lastDoneTime = _formatDateTime(DateTime.now());
                });
                _saveState(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? Colors.green : Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                isDone ? 'Done' : 'Missing',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearTimestamp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                'Clear',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _resetState(preserveTimestamp: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                'Reset',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                'Log Page >',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogPage extends StatefulWidget {
  @override
  _LogPageState createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<String> logList = [];

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      logList = prefs.getStringList('logList') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Page')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: logList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        logList[index],
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            child: Text(
              '< Home',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
