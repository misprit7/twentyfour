import 'package:flutter/material.dart';
import 'dart:math';
import 'games.dart';

enum Operation {
  None,
  Addition,
  Subtraction,
  Multiplication,
  Division,
  Reset,
  Sum,
  Product,
}

void main() {
  runApp(const MyApp());
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
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'twentyfour',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Twenty Four Game'),
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

  @override
  Widget build(BuildContext context) {
    // than having to individually change instances of widgets.
    return ButtonSquare();
  }
}

class ButtonSquare extends StatefulWidget {
  @override
  _ButtonSquareState createState() => _ButtonSquareState();
}

class _ButtonSquareState extends State<ButtonSquare> {
  bool isButtonVisible = true; // Initially, buttons are visible
  List<(int,int)> numbers = [(1,1), (2,1), (3,1), (4,1)];
  List<int> game = [1, 2, 3, 4];
  int num_select = -1;
  Operation opSelect = Operation.None;

void numberPress(int newSelect) {
  if (numbers[newSelect].$2 == 0) {
    return;
  }
  if (num_select == -1 || opSelect == Operation.None) {
    setState(() {
      num_select = newSelect;
    });
    return;
  }
  setState(() {
    (int, int) newNum = numbers[newSelect];
    (int, int) oldNum = numbers[num_select];

    var opMap = {
      Operation.Addition: addFrac,
      Operation.Subtraction: subFrac,
      Operation.Multiplication: mulFrac,
      Operation.Division: divFrac,
    };
    
    numbers[newSelect] = opMap[opSelect]!(oldNum, newNum);

    numbers[num_select] = (0,0);
    opSelect = Operation.None;
    num_select = newSelect;

  });
}

void opPress(Operation operation) {
    setState(() {
      if (operation == Operation.Reset) {
        reset();
      } else if (operation == Operation.Sum || operation == Operation.Product) {
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

    if(numbers.where((n) => n.$2 == 0).length == numbers.length - 1 && numbers.contains((24, 1))){
      reset();
    }

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
    });
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
        children: buttonLabels.map((label) {
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
              SizedBox(width: 16.0), // Add horizontal spacing between buttons
            ],
          );
        }).toList(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
                ButtonGroup([('++', Operation.Sum), ('××', Operation.Product)], screenSize.width / 4-16, 8, opPress, Operation.None),
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

