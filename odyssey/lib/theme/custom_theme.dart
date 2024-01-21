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
        dividerColor: darkMode,
        useMaterial3: true,
        splashColor: lightMode.withOpacity(0.4),
        primarySwatch: lightMode,
        primaryColor: lightMode,
        fontFamily: 'Quicksand',
        dialogBackgroundColor: lightMode,
        drawerTheme: DrawerThemeData(backgroundColor: darkMode),
        canvasColor: darkMode,
        snackBarTheme: SnackBarThemeData(actionTextColor: lightMode),
        chipTheme: ChipThemeData(
            backgroundColor: lightMode,
            selectedColor: darkMode,
            checkmarkColor: Colors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: lightMode,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: lightMode,
            selectionColor: lightMode,
            selectionHandleColor: lightMode),
        inputDecorationTheme: InputDecorationTheme(
            activeIndicatorBorder: BorderSide(color: lightMode),
            border:
                OutlineInputBorder(borderSide: BorderSide(color: lightMode))));
  }

  static ThemeData get darkTheme {
    return ThemeData(
        dialogTheme: DialogTheme(backgroundColor: darkMode),
        dividerColor: lightMode,
        useMaterial3: true,
        splashColor: darkMode.withOpacity(0.4),
        primarySwatch: darkMode,
        primaryColor: darkMode,
        fontFamily: 'Quicksand',
        dialogBackgroundColor: darkMode,
        drawerTheme: DrawerThemeData(backgroundColor: lightMode),
        canvasColor: lightMode,
        snackBarTheme: SnackBarThemeData(actionTextColor: lightMode),
        chipTheme: ChipThemeData(
            backgroundColor: darkMode,
            selectedColor: lightMode,
            checkmarkColor: Colors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: darkMode,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: darkMode,
            selectionColor: darkMode,
            selectionHandleColor: darkMode),
        inputDecorationTheme: InputDecorationTheme(
            activeIndicatorBorder: BorderSide(color: darkMode),
            border:
                OutlineInputBorder(borderSide: BorderSide(color: darkMode))));
  }
}
