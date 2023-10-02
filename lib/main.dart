import 'package:flutter/material.dart';
import 'dart:math';
import 'games.dart';

const int invalid = -999;

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
  List<int> numbers = [1, 2, 3, 4];
  int numSelect = -1;
  Operation opSelect = Operation.None;

void numberPress(int num_select) {
  if (numbers[num_select] == invalid) {
    return;
  }
  if (numSelect == -1 || opSelect == Operation.None) {
    setState(() {
      numSelect = num_select;
    });
    return;
  }
  setState(() {
    switch (opSelect) {
      case Operation.Addition:
        numbers[num_select] = numbers[numSelect] + numbers[num_select];
        break;
      case Operation.Subtraction:
        numbers[num_select] = numbers[numSelect] - numbers[num_select];
        break;
      case Operation.Multiplication:
        numbers[num_select] = numbers[numSelect] * numbers[num_select];
        break;
      case Operation.Division:
        numbers[num_select] = (numbers[numSelect] / numbers[num_select]).floor();
        break;
      default:
        break;
    }
    numbers[numSelect] = invalid;
    opSelect = Operation.None;
    numSelect = num_select;

  });
}

void opPress(Operation operation) {
    setState(() {
      if (operation == Operation.Reset) {
        reset();
      } else if (operation == Operation.Sum || operation == Operation.Product) {
        int result = operation == Operation.Sum ? 0 : 1;
        for (int i = 0; i < 4; ++i) {
          if (numbers[i] == invalid) {
            continue;
          }
          if (operation == Operation.Sum) {
            result += numbers[i];
          } else {
            result *= numbers[i];
          }
          numbers[i] = invalid;
        }
        if (numSelect != -1) {
          numbers[numSelect] = result;
        } else {
          numbers[0] = result;
        }
      } else {
        opSelect = operation;
      }
    });

    if(numbers.where((n) => n == invalid).length == numbers.length - 1 && numbers.contains(24)){
      reset();
    }

  }

  void reset() {
    setState(() {
      var rng = Random();
      List<int> puzzle = games[rng.nextInt(games.length)].toList()..shuffle(rng);
      for(int i = 0; i < 4; ++i){
        numbers[i] = puzzle[i];
      }
      opSelect = Operation.None;
      numSelect = -1;
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
                opacity: numbers[label.$2] == invalid ? 0.0 : 1.0,
                child: CustomButton(
                  label.$1,
                  buttonSize,
                  numSelect == label.$2,
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
                buildButtonRow([(numbers[0].toString(), 0), (numbers[1].toString(), 1)], buttonSize),
                SizedBox(height: 16.0), // Add horizontal spacing between buttons
                buildButtonRow([(numbers[2].toString(), 2), (numbers[3].toString(), 3)], buttonSize),
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

