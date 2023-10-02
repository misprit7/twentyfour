import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
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


class MyApp extends StatelessWidget {
  final AppSettings appSettings;
  const MyApp({Key? key, required this.appSettings}) : super(key : key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'twentyfour',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ButtonSquare(appSettings: appSettings),
    );
  }
}


class ButtonSquare extends StatefulWidget {
  final AppSettings appSettings;
  const ButtonSquare({required this.appSettings});
  @override
  _ButtonSquareState createState() => _ButtonSquareState();
}

class _ButtonSquareState extends State<ButtonSquare> {
  bool isButtonVisible = true; // Initially, buttons are visible
  List<(int,int)> numbers = [(1,1), (2,1), (3,1), (4,1)];
  List<(List<(int, int)>, int)> history = [];
  int history_point = 0;
  int num_select = -1;
  Operation opSelect = Operation.None;
  Settings _settings = Settings();

  void checkFinished(){
    if(numbers.where((n) => n.$2 == 0).length == numbers.length - 1 && numbers.contains((24, 1))){
      reset();
    }
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

      if(history_point < history.length-1){
        history.removeRange(history_point + 1, history.length);
      }
      history.add((List<(int,int)>.from(numbers), num_select));
      history_point += 1;
      // print(history);
      checkFinished();

    });
  }

  void opPress(Operation operation) {
    setState(() {
      if (operation == Operation.Reset) {
        reset();
      } else if(operation == opSelect){
        opSelect = Operation.None;
        return;
      } else if(operation == Operation.Undo) {
        // print(history);
        if(history_point <= 0){
          return;
        }
        --history_point;
        numbers = List<(int,int)>.from(history[history_point].$1);
        num_select = history[history_point].$2;
        opSelect = Operation.None;
      } else if(operation == Operation.Redo){
        // print(history);
        if(history_point >= history.length - 1){
          return;
        }
        ++history_point;
        numbers = List<(int,int)>.from(history[history_point].$1);
        num_select = history[history_point].$2;
        opSelect = Operation.None;
      } else if(operation == Operation.Sum || operation == Operation.Product) {
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
      } else {
        opSelect = operation;
      }
    });

    checkFinished();

  }

  void reset() {
    setState(() {
      var rng = Random();
      List<int> game = games[rng.nextInt(games.length)].toList()..shuffle(rng);
      for(int i = 0; i < 4; ++i){
        numbers[i] = (game[i], 1);
      }
      opSelect = Operation.None;
      num_select = -1;
      history = [(List<(int,int)>.from(numbers), -1)];
      history_point = 0;
    });
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

  void _updateSettings(Settings newSettings) {
    setState(() {
      _settings = newSettings; // Update the settings
    });
  }

  @override
  void initState(){
    super.initState();
    reset();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = screenSize.width < screenSize.height
        ? screenSize.width / 2-32
        : screenSize.height / 2-32;

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
            icon: Icon(Icons.settings), // Replace with your desired icon
            onPressed: () {_openSettingsDialog(context);}
          ),
        ],
      ),
      body: Center(
        child: 
         Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                buildButtonRow([(strFrac(numbers[0]), 0), (strFrac(numbers[1]), 1)], buttonSize),
                SizedBox(height: 16.0), // Add horizontal spacing between buttons
                buildButtonRow([(strFrac(numbers[2]), 2), (strFrac(numbers[3]), 3)], buttonSize),
                SizedBox(height: 16.0), // Add horizontal spacing between buttons
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ButtonGroup([('+', Operation.Addition), ('-', Operation.Subtraction), ('×', Operation.Multiplication), ('÷', Operation.Division)], screenSize.width / 4-16, 8, opPress, opSelect),
              ],
            ),
            SizedBox(height: 16.0), // Add vertical margin
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ButtonGroup([('«', Operation.Undo), ('++', Operation.Sum), ('××', Operation.Product), ('»', Operation.Redo)], screenSize.width / 4-16, 8, opPress, Operation.None),
              ],
            ),
          ],
        )
      ),
      floatingActionButton:
        FloatingActionButton(
          onPressed: reset,
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
    final primaryColor = widget.isActive ? Colors.blue : Theme.of(context).colorScheme.surfaceVariant;
    final textColor = widget.isActive ? Colors.white : Colors.black;

    return Container(
      width: widget.size,
      height: widget.size,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          primary: primaryColor,
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 24.0,
              color: textColor,
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

