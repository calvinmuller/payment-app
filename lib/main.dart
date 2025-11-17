import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class IntentService {
  static const platform = MethodChannel('com.example.intent_app/intent');

  /// Get the intent data that was passed to this activity
  static Future<Map<dynamic, dynamic>?> getIntentData() async {
    try {
      final Map<dynamic, dynamic>? result = await platform.invokeMethod('getIntentData');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to get intent data: '${e.message}'.");
      return null;
    }
  }

  /// Set the result and finish the activity
  /// [resultCode] - Activity.RESULT_OK (-1) or Activity.RESULT_CANCELED (0)
  /// [data] - Map of key-value pairs to return to the calling activity
  static Future<void> setResultAndFinish({
    int resultCode = -1, // Activity.RESULT_OK
    Map<String, dynamic>? data,
  }) async {
    try {
      await platform.invokeMethod('setResult', {
        'resultCode': resultCode,
        'data': data ?? {},
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to set result: '${e.message}'.");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<dynamic, dynamic>? _intentData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIntentData();
  }

  Future<void> _loadIntentData() async {
    final data = await IntentService.getIntentData();
    setState(() {
      _intentData = data;
      _loading = false;
    });
  }

  void _sendSuccessResult() {
    IntentService.setResultAndFinish(
      resultCode: -1, // Activity.RESULT_OK
      data: {
        'status': 'success',
        'message': 'Operation completed successfully',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void _sendCancelResult() {
    IntentService.setResultAndFinish(
      resultCode: 0, // Activity.RESULT_CANCELED
      data: {
        'status': 'cancelled',
        'message': 'Operation was cancelled',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Intent Data Received:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: _intentData == null || _intentData!.isEmpty
                            ? const Text('No intent data received')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _intentData!.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '${entry.key}: ${entry.value}',
                                      style: const TextStyle(fontFamily: 'monospace'),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Send Result:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _sendSuccessResult,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Send Success Result'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _sendCancelResult,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Send Cancel Result'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
