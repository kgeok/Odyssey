// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables

import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odyssey/theme/custom_theme.dart';

var buttonaction1 = "";
var buttonaction2 = "";
var dialogColor;

var dialogHeader =
    GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.white);

var dialogBody =
    GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.white);

void simpleDialog(
    BuildContext context, var header, var body1, var body2, var type) {
  switch (type) {
    case "warning":
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor = Colors.orange[800];
      break;

    case "error":
      buttonaction1 = "";
      buttonaction2 = "Dismiss";
      dialogColor = Colors.red[900];
      break;

    case "info":
      buttonaction1 = "";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
      break;

    default:
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
      break;
  }
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: dialogColor,
          title: Text(header, style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(body1, style: dialogBody),
                Text(body2, style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonaction1, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonaction2, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void complexDialog(BuildContext context, var header, var body1, var body2,
    var body3, var body4, var type) {
  switch (type) {
    case "warning":
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor = Colors.orange[800];
      break;

    case "error":
      buttonaction1 = "";
      buttonaction2 = "Dismiss";
      dialogColor = Colors.red[900];
      break;

    case "info":
      buttonaction1 = "";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
      break;

    default:
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
      break;
  }
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: dialogColor,
          title: Text(header, style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(body1, style: dialogBody),
                Text("", style: dialogBody),
                Text(body2, style: dialogBody),
                Text("", style: dialogBody),
                Text(body3, style: dialogBody),
                Text("", style: dialogBody),
                Text(body4, style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonaction1, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonaction2, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void onboardDialog(BuildContext context) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    constraints: const BoxConstraints(maxWidth: 500),
    builder: (BuildContext context) {
      return Container(
          constraints: const BoxConstraints(maxWidth: 500),
          color: MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1),
          child: FractionallySizedBox(
              // heightFactor: 0.9,
              child: SingleChildScrollView(
                  child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 35, 0, 0),
                child: Text("Welcome to Odyssey",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Colors.white)),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Text(
                      "Keep track of the destinations you traveled with customizable pins on a beautiful map.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Text(
                      "With the Journal, you can get a glance of your overall pins and keep notes of where you went and where you want to go.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Text('Tap anywhere on the map to set a Pin',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Tap ",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white)),
                      const WidgetSpan(
                          child: Icon(
                        Icons.menu,
                        color: Colors.white,
                      )),
                      TextSpan(
                          text:
                              " to open the Journal and see an overview of all your entries",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white))
                    ]),
                  )),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Tap ",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white)),
                      const WidgetSpan(
                          child: Icon(
                        Icons.push_pin,
                        color: Colors.white,
                      )),
                      TextSpan(
                          text: " to see customization and more options",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white))
                    ]),
                  )),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Tap ",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white)),
                      const WidgetSpan(
                          child: Icon(
                        Icons.my_location,
                        color: Colors.white,
                      )),
                      TextSpan(
                          text:
                              " to move the map to your current location (Requires your current location)",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white))
                    ]),
                  )),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Tap ",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white)),
                      const WidgetSpan(
                          child: Icon(
                        Icons.radar,
                        color: Colors.white,
                      )),
                      TextSpan(
                          text:
                              " to open Near By and see places near you (Requires your current location)",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white))
                    ]),
                  )),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Tap ",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white)),
                      const WidgetSpan(
                          child: Icon(
                        Icons.add,
                        color: Colors.white,
                      )),
                      const WidgetSpan(
                          child: Icon(
                        Icons.remove,
                        color: Colors.white,
                      )),
                      TextSpan(
                          text: " to zoom in and out of the map",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white))
                    ]),
                  )),
              Center(
                  child: SingleChildScrollView(
                      child: Column(children: [
                const SizedBox(height: 30),
                TextButton(
                  style: ButtonStyle(
                      minimumSize:
                          const WidgetStatePropertyAll<Size>(Size(250, 50)),
                      backgroundColor: WidgetStatePropertyAll<Color>(
                        MediaQuery.of(context).platformBrightness ==
                                Brightness.light
                            ? darkMode.withOpacity(1)
                            : lightMode.withOpacity(1),
                      ),
                      enableFeedback: true),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Get Started",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16)),
                ),
                const SizedBox(height: 50),
              ])))
            ],
          ))));
    },
  );
}

void aboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          title: Text("Odyssey", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Version $version ($release)", style: dialogBody),
                const Text(''),
                Text('With 💖 by Kevin George', style: dialogBody),
                const Text(''),
                Text('http://kgeok.github.io/', style: dialogBody),
                const Text(''),
                Text('Powered by Google Maps, Material Design and Flutter.',
                    style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: Text('Acknowledgements', style: dialogBody),
                onPressed: () {
                  showLicensePage(
                      context: context,
                      useRootNavigator: false,
                      applicationName: "Odyssey",
                      applicationVersion: version,
                      applicationLegalese: "Kevin George");
                }),
            TextButton(
                child: Text('Dismiss', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ]);
    },
  );
}

void helpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor:
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? lightMode.withOpacity(1)
                  : darkMode.withOpacity(1),
          title: Text("Quick Start", style: dialogHeader),
          content: SingleChildScrollView(
              child: ListBody(children: [
            Text('Tap anywhere on the map to set a Pin', style: dialogBody),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.menu,
                  color: Colors.white,
                )),
                TextSpan(
                    text:
                        " to open the Journal and see an overview of all your entries",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.push_pin,
                  color: Colors.white,
                )),
                TextSpan(
                    text: " to see customization and more options",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.my_location,
                  color: Colors.white,
                )),
                TextSpan(
                    text:
                        " to move the map to your current location (Requires your current location)",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.radar,
                  color: Colors.white,
                )),
                TextSpan(
                    text:
                        " to open Near By and see places near you (Requires your current location)",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.add,
                  color: Colors.white,
                )),
                const WidgetSpan(
                    child: Icon(
                  Icons.remove,
                  color: Colors.white,
                )),
                TextSpan(
                    text: " to zoom in and out of the map", style: dialogBody)
              ]),
            ),
          ])),
          actions: [
            TextButton(
              child: Text('Dismiss', style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}
