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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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

  void toggleButtonVisibility() {
    setState(() {
      isButtonVisible = !isButtonVisible; // Toggle button visibility
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = screenSize.width < screenSize.height
        ? screenSize.width / 2-32
        : screenSize.height / 2-32;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Opacity(
              opacity: isButtonVisible ? 1.0 : 0.0, // Control opacity based on state
              child: CustomButton('1', buttonSize, onPressed: toggleButtonVisibility,),
            ),
            SizedBox(width: 16.0), // Add horizontal margin
            Opacity(
              opacity: isButtonVisible ? 1.0 : 0.0, // Control opacity based on state
              child: CustomButton('2', buttonSize),
            ),
          ],
        ),
        SizedBox(height: 16.0), // Add vertical margin
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Opacity(
              opacity: isButtonVisible ? 1.0 : 0.0, // Control opacity based on state
              child: CustomButton('3', buttonSize),
            ),
            SizedBox(width: 16.0), // Add horizontal margin
            Opacity(
              opacity: isButtonVisible ? 1.0 : 0.0, // Control opacity based on state
              child: CustomButton('4', buttonSize),
            ),
          ],
        ),
        SizedBox(height: 16.0), // Add vertical margin
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ButtonGroup(['+', '-', '×', '÷'], screenSize.width / 4-16, 8),
          ],
        ),
        SizedBox(height: 16.0), // Add vertical margin
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ButtonGroup(['++', '××'], screenSize.width / 4-16, 8),
          ],
        ),
      ],
    );
  }
}

class CustomButton extends StatelessWidget {
  final String number;
  final double size;
  final VoidCallback? onPressed; // Callback function

  CustomButton(this.number, this.size, {this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed, // Assign the callback function to the button's onPressed
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}

class ButtonGroup extends StatelessWidget {
  final List<String> numbers;
  final double size;
  final double spacing; // Define spacing between buttons

  ButtonGroup(this.numbers, this.size, this.spacing);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * numbers.length.toDouble() + spacing * (numbers.length - 1), // Calculate total width
      height: size, // Set a fixed height
      child: Row(
        children: numbers.asMap().entries.map((entry) {
          final index = entry.key;
          final number = entry.value;
          return Row(
            children: <Widget>[
              CustomButton(number, size),
              if (index != numbers.length - 1) SizedBox(width: spacing), // Add spacing between buttons
            ],
          );
        }).toList(),
      ),
    );
  }
}

