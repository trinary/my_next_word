import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Next Word',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      ),
      home: MyHomePage(title: 'My Next Word'),
    );
  }
}

class MyHomePage extends StatefulWidget {
   MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _recording = false;
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechAvailable = false;
  String _currentWords = '';
  String _lastWords = '';
  final String _selectedLocaleId = 'en_US';

  @override
  void initState() {
    super.initState();
    debugPrint('running initState, about to initSpeech');
    _initSpeech();
  }

  void errorListener(SpeechRecognitionError error) {
    debugPrint(error.errorMsg.toString());
  }

  void statusListener(String status) async {
    debugPrint("status $status");
    if (status == "done" && _speechEnabled) {
      setState(() {
      _lastWords += " $_currentWords";
      _currentWords = "";
      _speechEnabled = false;
      });
      await _startListening();
    }
  }

  printLocales() async {
    var locales = await _speechToText.locales();
    for (var locale in locales) {
      debugPrint(locale.name);
      debugPrint(locale.localeId);
    }
  }

  void _initSpeech() async {
    _speechAvailable = await _speechToText.initialize(
      onError: errorListener,
      onStatus: statusListener,
      debugLogging: true,
    );
    debugPrint("initSpeech running, _speechAvailable: $_speechAvailable");
    setState(() {});
  }

  Future _startListening() async {
    await _stopListening();
    await Future.delayed(const Duration(milliseconds: 50));
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _selectedLocaleId,
      listenOptions: SpeechListenOptions(
        cancelOnError: false, 
        partialResults: true, 
        listenMode: ListenMode.dictation, 
        onDevice: true
      )
    );
    setState(() {_speechEnabled = true;});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _currentWords = result.recognizedWords;
    });
  }

  Future _stopListening() async {
    setState(() {
      _speechEnabled = false;      
    });
    await _speechToText.stop();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var barColor = _speechToText.isListening ? Colors.red : Colors.blue;
   
    return Scaffold(
      appBar: AppBar(
        backgroundColor: barColor,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Current word list:'),
            Text(
              _currentWords,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: 'Toggle Recording',
        child: Icon(_speechToText.isListening ? Icons.mic : Icons.mic_external_off),
      ),
    );
  }
}
