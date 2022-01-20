import 'package:odyssey/main.dart';

void simpleDialog(BuildContext context, var header, var body1, var body2, var type){

switch (type) {

    case "warning":
    var buttonaction1 = "Cancel";
    var buttonaction2 = "OK";
    var dialogColor = Colors.orange[800];
    break;

    case "error":
    var buttonaction1 = "";
    var buttonaction2 = "Dismiss";
    var dialogColor = Colors.red[900];
    break;

    default:
    var buttonaction1 = "Cancel";
    var buttonaction2 = "OK";
    var dialogColor = MediaQuery.of(context).platformBrightness == Brightness.light
                ? lightMode.withOpacity(0.8)
                : darkMode.withOpacity(0.8),
    break;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: type,
            title: Text(header,
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(body1,
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(body2,
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(buttonaction1,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(buttonaction2,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

}
