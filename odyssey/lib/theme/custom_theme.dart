import 'package:flutter/material.dart';

Map<int, Color> color = {
  50: const Color.fromRGBO(0, 105, 148, .6),
  100: const Color.fromRGBO(0, 105, 148, .7),
  200: const Color.fromRGBO(0, 105, 148, .8),
  300: const Color.fromRGBO(0, 105, 148, .9),
  400: const Color.fromRGBO(0, 105, 148, 1),
  500: const Color.fromRGBO(0, 8, 74, .6),
  600: const Color.fromRGBO(0, 8, 74, .7),
  700: const Color.fromRGBO(0, 8, 74, .8),
  800: const Color.fromRGBO(0, 8, 74, .9),
  900: const Color.fromRGBO(0, 8, 74, 1),
};

MaterialColor lightMode = MaterialColor(0xff006694, color);
MaterialColor darkMode = MaterialColor(0xff00084a, color);

class CustomTheme {
  static ThemeData get lightTheme {
    //1
    return ThemeData(
      //2
      dialogTheme: DialogTheme(backgroundColor: lightMode),
      useMaterial3: false,
      splashColor: darkMode,
      primarySwatch: lightMode,
      primaryColor: lightMode,
      fontFamily: 'Quicksand',
      dialogBackgroundColor: lightMode,
      canvasColor: darkMode,
      appBarTheme: AppBarTheme(
        backgroundColor: lightMode,
      ),
      textTheme: const TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
          headline1: TextStyle(color: Colors.white),
          headline2: TextStyle(color: Colors.white)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      dialogTheme: DialogTheme(backgroundColor: darkMode),
      useMaterial3: false,
      splashColor: lightMode,
      primarySwatch: darkMode,
      primaryColor: darkMode,
      fontFamily: 'Quicksand',
      dialogBackgroundColor: darkMode,
      canvasColor: lightMode,
      appBarTheme: AppBarTheme(
        backgroundColor: darkMode,
      ),
      textTheme: const TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
          headline1: TextStyle(color: Colors.white),
          headline2: TextStyle(color: Colors.white)),
    );
  }
}
