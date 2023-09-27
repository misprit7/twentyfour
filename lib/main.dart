import 'package:flutter/material.dart';

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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: ButtonSquare()
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
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
  int opSelect = -1;

  void numberPress(int i) {
    if(numSelect != -1 || opSelect == -1){
      if(numbers[i] != -999){
        setState(() {
          numSelect = i;
        });
      }
      return;
    }
    setState(() {
      if(opSelect == 0){
        numbers[i] == numbers[numSelect] + numbers[i];
      } else if(opSelect == 1){
        numbers[i] == numbers[numSelect] - numbers[i];
      } else if(opSelect == 2){
        numbers[i] == numbers[numSelect] * numbers[i];
      } else if(opSelect == 3){
        numbers[i] == numbers[numSelect] / numbers[i];
      }
      numbers[numSelect] = -999;
      numSelect = i;
    });
  }

  void opPress(int i) {
    if(0 <= i && i <= 3){
      setState((){ opSelect = i; });
      return;
    }
    setState((){
      int reduced = numbers.reduce((a, b){ return i == 4 ? a+b : a*(b == -999 ? 1 : b); });
      for(int i = 0; i < 4; ++i){numbers[i] = -999;}
      if(numSelect != -1){
        numbers[numSelect] = reduced;
      } else {
        numbers[0] = reduced;
      }
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
                opacity: numbers[label.$2] == -999 ? 0.0 : 1.0,
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

    return Column(
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
            ButtonGroup([('+', 0), ('-', 1), ('×', 2), ('÷', 3)], screenSize.width / 4-16, 8, opPress),
          ],
        ),
        SizedBox(height: 16.0), // Add vertical margin
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ButtonGroup([('++', 4), ('××', 5)], screenSize.width / 4-16, 8, opPress),
          ],
        ),
      ],
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
  final List<(String, int)> labels;
  final double size;
  final double spacing; // Define spacing between buttons
  final void Function(int) onPressed;

  ButtonGroup(this.labels, this.size, this.spacing, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * labels.length.toDouble() + spacing * (labels.length - 1), // Calculate total width
      height: size, // Set a fixed height
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final index = entry.key;
          final number = entry.value.$1;
          final i = entry.value.$2;
          return Row(
            children: <Widget>[
              CustomButton(number, size, false, onPressed: (){onPressed(i);}),
              if (index != labels.length - 1) SizedBox(width: spacing), // Add spacing between buttons
            ],
          );
        }).toList(),
      ),
    );
  }
}

