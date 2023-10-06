import 'package:flutter/material.dart';
import 'games.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<Color> themeColors = [Colors.deepOrange, Colors.cyan, Colors.purple, Colors.lime];

class AppSettings {
  final SharedPreferences _prefs;

  AppSettings(this._prefs);

  int getIntSetting(String key, int defaultValue) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  bool getBoolSetting(String key, bool defaultValue) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setIntSetting(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  Future<void> setBoolSetting(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
}

Settings readSettings(AppSettings appSettings){
  Settings ret = Settings();
  ret.minDifficulty = appSettings.getIntSetting('minDifficulty', 0).toDouble();
  ret.maxDifficulty = appSettings.getIntSetting('maxDifficulty', games.length).toDouble();
  ret.themeColor = Color(appSettings.getIntSetting('themeColor', Colors.deepOrange.value));
  ret.timerEnabled = appSettings.getBoolSetting('timerEnabled', true);
  ret.darkMode = appSettings.getBoolSetting('darkMode', false);

  if(!themeColors.map((c)=>c.value).toList().contains(ret.themeColor.value)){
    ret.themeColor = themeColors[0];
  }

  return ret;
}

class ColorSelector extends StatefulWidget {
  final Function onSelect;
  final Color initSelected;


  const ColorSelector({required this.onSelect, required this.initSelected});

  @override
  _ColorSelectorState createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Color selected = Colors.deepOrange;

  @override
  void initState(){
    super.initState();
    selected = widget.initSelected;
  }

  @override
  Widget build(BuildContext context) {
    int selectedIndex = themeColors.map((c)=>c.value).toList().indexOf(selected.value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: themeColors.asMap().entries.map((entry) {
        int idx = entry.key;
        Color color = entry.value;
        return GestureDetector(
          onTap: () {
            setState(() {
              selected = color;
              widget.onSelect(color);
            });
          },
          child: Container(
            margin: EdgeInsets.all(8.0),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: selectedIndex == idx ? Theme.of(context).colorScheme.outline : Colors.transparent,
                width: 3.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final AppSettings appSettings;
  final ValueChanged<Settings> onSettingsChanged;
  final Settings initialSettings;

  SettingsPage({
    required this.appSettings,
    required this.onSettingsChanged,
    required this.initialSettings,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Settings _settings;

  @override
  void initState() {
    super.initState();
    _settings = readSettings(widget.appSettings);
  }

  void _saveSettings() {
    // Save the current value to settings
    widget.appSettings.setIntSetting('minDifficulty', _settings.minDifficulty.round());
    widget.appSettings.setIntSetting('maxDifficulty', _settings.maxDifficulty.round());
    widget.appSettings.setIntSetting('themeColor', _settings.themeColor.value);
    widget.appSettings.setBoolSetting('timerEnabled', _settings.timerEnabled);
    widget.appSettings.setBoolSetting('darkMode', _settings.darkMode);
    // Navigator.pop(context); // Close the settings page
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Min difficulty: ${_settings.minDifficulty.toStringAsFixed(0)}'),
          Slider(
            value: _settings.minDifficulty,
            min: 0,
            max: games.length.toDouble(),
            onChanged: (value) {
              setState(() {
                if(value < _settings.maxDifficulty){
                  _settings.minDifficulty = value;
                }
              });
            },
          ),
          Text('Max difficulty: ${_settings.maxDifficulty.toStringAsFixed(0)}'),
          Slider(
            value: _settings.maxDifficulty,
            min: 0,
            max: games.length.toDouble(),
            onChanged: (value) {
              setState(() {
                if(value > _settings.minDifficulty){
                  _settings.maxDifficulty = value;
                }
              });
            },
          ),
          Row(
            children: [
              Checkbox(
                value: _settings.timerEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings.timerEnabled = value ?? false;
                  });
                },
              ),
              Text('Enable timer'),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _settings.darkMode,
                onChanged: (value) {
                  setState(() {
                    _settings.darkMode = value ?? false;
                  });
                },
              ),
              Text('Dark mode'),
            ],
          ),
          ColorSelector(onSelect: (Color color){
              setState((){
                _settings.themeColor = color;
              });
            },
            initSelected: _settings.themeColor,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog without saving changes
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _saveSettings();
            widget.onSettingsChanged(_settings); // Pass new settings back to the main app
            Navigator.of(context).pop(); // Close the dialog and pass new settings
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class Settings {
  double minDifficulty = 0;
  double maxDifficulty = games.length.toDouble();
  bool timerEnabled = true;
  bool darkMode = false;
  Color themeColor = Colors.deepOrange;
}
