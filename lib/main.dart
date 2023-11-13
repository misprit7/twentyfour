import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';
import 'games.dart';
import 'settings.dart';

enum Operation {
  None,
  Addition,
  Subtraction,
  Multiplication,
  Division,
  Reset,
  Sum,
  Product,
  Undo,
  Redo,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(appSettings: AppSettings(prefs)));
}

(int,int) reduceFrac((int,int) r){
    int g = r.$2.gcd(r.$1);
    return (
      r.$1 ~/ g,
      r.$2 ~/ g,
    );
}

(int,int) addFrac((int,int) a, (int,int) b){
  return reduceFrac((
    a.$1*b.$2+b.$1*a.$2,
    a.$2*b.$2
  ));
}

(int,int) subFrac((int,int) a, (int,int) b){
  return addFrac(a, (-b.$1, b.$2));
}

(int,int) mulFrac((int,int) a, (int,int) b){
  return reduceFrac((
      a.$1 * b.$1,
      a.$2 * b.$2
  ));
}

(int,int) divFrac((int,int) a, (int,int) b){
  return mulFrac(a, (b.$2, b.$1));
}

String strFrac((int, int) r){
  if(r.$2 == 1){
    return r.$1.toString();
  }
  return '${r.$1.toString()}/${r.$2.toString()}';
}


class MyApp extends StatefulWidget {
  final AppSettings appSettings;
  const MyApp({Key? key, required this.appSettings}) : super(key : key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _currentTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
    useMaterial3: true,
  );


  void _changeTheme(bool darkMode, Color themeColor) {
    Brightness mode = darkMode ? Brightness.dark : Brightness.light;
    setState(() {
      _currentTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor, brightness: mode),
        brightness: mode,
        useMaterial3: true,
      );
    });
  }

  @override
  void initState(){
    super.initState();
    Settings s = readSettings(widget.appSettings);
    _changeTheme(s.darkMode, s.themeColor);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'twentyfour',
      theme: _currentTheme,
      home: ButtonSquare(appSettings: widget.appSettings, changeTheme: _changeTheme),
    );
  }
}


class ButtonSquare extends StatefulWidget {
  final AppSettings appSettings;
  final Function changeTheme;
  const ButtonSquare({required this.appSettings, required this.changeTheme});
  @override
  _ButtonSquareState createState() => _ButtonSquareState();
}

class _ButtonSquareState extends State<ButtonSquare> {
  bool isButtonVisible = true; // Initially, buttons are visible
  List<(int,int)> numbers = [(1,1), (2,1), (3,1), (4,1)];
  List<(List<(int, int)>, int)> history = [];
  int history_point = 0;
  int num_select = -1;

  late Timer timer;
  int timer_seconds = 0;
  int num_solves = 0;
  
  Operation opSelect = Operation.None;
  Settings _settings = Settings();

  void checkFinished(){
    if(numbers.where((n) => n.$2 == 0).length == numbers.length - 1 && numbers.contains((24, 1))){
      newGame();
      ++num_solves;
    }
  }

  void addHistory(){
    if(history_point < history.length-1){
      history.removeRange(history_point + 1, history.length);
    }
    history.add((List<(int,int)>.from(numbers), num_select));
    history_point += 1;
  }

  void numberPress(int newSelect) {
    if (numbers[newSelect].$2 == 0) {
      return;
    }
    if(num_select == newSelect){
      setState(() {
        num_select = -1;
        history[history_point] = (history[history_point].$1, num_select);
      });
      return;
    }
    if (num_select == -1 || opSelect == Operation.None) {
      setState(() {
        num_select = newSelect;
        history[history_point] = (history[history_point].$1, num_select);
      });
      return;
    }
    setState(() {
      (int, int) newNum = numbers[newSelect];
      (int, int) oldNum = numbers[num_select];
      if(newNum.$1 == 0 && opSelect == Operation.Division){
        return;
      }

      var opMap = {
        Operation.Addition: addFrac,
        Operation.Subtraction: subFrac,
        Operation.Multiplication: mulFrac,
        Operation.Division: divFrac,
      };

      history[history_point] = (history[history_point].$1, num_select);
      
      numbers[newSelect] = opMap[opSelect]!(oldNum, newNum);
      numbers[num_select] = (0,0);
      opSelect = Operation.None;
      num_select = newSelect;

      addHistory();

      checkFinished();

    });
  }

  void opPress(Operation operation) {
    setState(() {
      if (operation == Operation.Reset) {
        newGame();
        timer_seconds = 0;
        num_solves = 0;
      } else if(operation == opSelect){
        opSelect = Operation.None;
        return;
      } else if(operation == Operation.Undo) {
        if(history_point <= 0){
          return;
        }
        --history_point;
        numbers = List<(int,int)>.from(history[history_point].$1);
        num_select = history[history_point].$2;
        opSelect = Operation.None;
      } else if(operation == Operation.Redo){
        if(history_point >= history.length - 1){
          return;
        }
        ++history_point;
        numbers = List<(int,int)>.from(history[history_point].$1);
        num_select = history[history_point].$2;
        opSelect = Operation.None;
      } else if(operation == Operation.Sum || operation == Operation.Product) {
        if(numbers.where((n) => n.$2 == 0).length == numbers.length - 1){
          return;
        }
        (int,int) result = operation == Operation.Sum ? (0,1) : (1,1);
        for (int i = 0; i < 4; ++i) {
          if (numbers[i].$2 == 0) {
            continue;
          }
          if (operation == Operation.Sum) {
            result = addFrac(result, numbers[i]);
          } else {
            result = mulFrac(result, numbers[i]);
          }
          numbers[i] = (0,0);
        }
        if (num_select != -1) {
          numbers[num_select] = result;
        } else {
          numbers[0] = result;
        }
        addHistory();
      } else {
        opSelect = operation;
      }
      checkFinished();
    });


  }

  void newGame() {
    var rng = Random();
    int index = rng.nextInt(_settings.maxDifficulty.floor()-_settings.minDifficulty.floor()) + _settings.minDifficulty.floor();
    List<int> game = games[index].toList()..shuffle(rng);
    for(int i = 0; i < 4; ++i){
      numbers[i] = (game[i], 1);
    }
    opSelect = Operation.None;
    num_select = -1;
    history = [(List<(int,int)>.from(numbers), -1)];
    history_point = 0;
  }

  void _openSettingsDialog(BuildContext context) async {
    final newSettings = await showDialog<Settings>(
      context: context,
      builder: (BuildContext context) {
        return SettingsPage(
          appSettings: widget.appSettings,
          onSettingsChanged: _updateSettings,
          initialSettings: _settings, // Pass the current settings
        );
      },
    );

    if (newSettings != null) {
      // Update the settings if the dialog was closed with new settings
      _updateSettings(newSettings);
    }
  }

  void _openHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("""
Make the number 24 using +, -, ×, ÷ and all four numbers!

For example, if your numbers were [1, 3, 6, 8], a solution would be (6-3)×8×1=24.

Use « and » to undo and redo your last move respectively. ++ adds all remaining numbers, and similarly ×× multiplies everything left.

All the puzzles given are guaranteed to be possible.

The difficulty sliders in settings represent average solve times experimentaly measured at 4nums.com.
              """)
            ]
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ]
        );
      },
    );
  }

  void _updateSettings(Settings newSettings) {
    setState(() {
      _settings = newSettings; // Update the settings
      widget.changeTheme(_settings.darkMode, _settings.themeColor);
    });
  }

  @override
  void initState(){
    super.initState();
    _settings = readSettings(widget.appSettings);
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        ++timer_seconds;
      });
    });
    newGame();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double minWidth = screenSize.width / 2-32;
    double minHeight = (screenSize.height-128)/ 4;
    final buttonSize = minWidth < minHeight ? minWidth : minHeight;

    Row buildButtonRow(List<(String, int)> buttonLabels, double buttonSize) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttonLabels.asMap().entries.map((entry) {
          int index = entry.key;
          var label = entry.value;
          return Row(
            children: [
              Opacity(
                opacity: numbers[label.$2].$2 == 0 ? 0.0 : 1.0,
                child: CustomButton(
                  label.$1,
                  buttonSize,
                  num_select == label.$2,
                  onPressed: (){numberPress(label.$2);},
                ),
              ),
              SizedBox(width: index < buttonLabels.length - 1 ? 16.0 : 0), // Add horizontal spacing between buttons
            ],
          );
        }).toList(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.question_mark), // Replace with your desired icon
            onPressed: () {_openHelpDialog(context);}
          ),
          IconButton(
            icon: Icon(Icons.settings), // Replace with your desired icon
            onPressed: () {_openSettingsDialog(context);}
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: 
         Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 24.0),
            Row(
              children:[
                const SizedBox(width: 24.0),
                ...(_settings.timerEnabled ? [
                  const Icon(Icons.timer),
                  const SizedBox(width: 8.0),
                  Text(
                    _settings.timerEnabled ? '$timer_seconds' : '',
                    style: const TextStyle(fontSize:36),
                  ),
                ] : []),
                const Spacer(),
                const Icon(Icons.emoji_events),
                const SizedBox(width: 8.0),
                Text(
                  '$num_solves',
                  style: const TextStyle(fontSize:36),
                ),
                const SizedBox(width: 24.0),
              ]
            ),
            const SizedBox(height: 16.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                buildButtonRow([(strFrac(numbers[0]), 0), (strFrac(numbers[1]), 1)], buttonSize),
                const SizedBox(height: 16.0), // Add horizontal spacing between buttons
                buildButtonRow([(strFrac(numbers[2]), 2), (strFrac(numbers[3]), 3)], buttonSize),
                const SizedBox(height: 16.0), // Add horizontal spacing between buttons
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ButtonGroup(
                  const [('+', Operation.Addition), ('-', Operation.Subtraction), ('×', Operation.Multiplication), ('÷', Operation.Division)],
                  min(screenSize.width / 4-16, buttonSize*0.75),
                  8,
                  opPress,
                  opSelect
                ),
              ],
            ),
            const SizedBox(height: 16.0), // Add vertical margin
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ButtonGroup(
                  const [('«', Operation.Undo), ('++', Operation.Sum), ('××', Operation.Product), ('»', Operation.Redo)],
                  min(screenSize.width / 4-16, buttonSize*0.75),
                  8,
                  opPress,
                  Operation.None
                ),
              ],
            ),
          ],
        )
      ),
      floatingActionButton:
        FloatingActionButton(
          onPressed: (){opPress(Operation.Reset);},
          tooltip: 'Increment',
          child: const Icon(Icons.restart_alt),
        ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class CustomButton extends StatefulWidget {
  final String label;
  final double size;
  final bool isActive; // Added isActive property
  final VoidCallback? onPressed;

  CustomButton(
    this.label,
    this.size,
    this.isActive,
    {this.onPressed}
  );

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {

    return Container(
      width: widget.size,
      height: widget.size,
      child: widget.isActive ? FilledButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 24.0,
            ),
          ),
        ),
      ) : FilledButton.tonal( 
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 24.0,
            ),
          ),
        ),
      ),
    );
  }
}

class ButtonGroup extends StatelessWidget {
  final List<(String, Operation)> labels;
  final double size;
  final double spacing; // Define spacing between buttons
  final void Function(Operation) onPressed;
  final Operation active;

  ButtonGroup(this.labels, this.size, this.spacing, this.onPressed, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * labels.length.toDouble() + spacing * (labels.length - 1),
      height: size,
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final index = entry.key;
          final operation = entry.value.$2;
          return Row(
            children: <Widget>[
              CustomButton(
                entry.value.$1,
                size,
                active == operation,
                onPressed: () {
                  onPressed(operation);
                },
              ),
              if (index != labels.length - 1) SizedBox(width: spacing),
            ],
          );
        }).toList(),
      ),
    );
  }
}

