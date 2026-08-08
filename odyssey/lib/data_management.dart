// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* These are the default value we use for settings
These will also be the values to fall back on in case DB can't be loaded
They will also be loaded into DB on init */

//Center of the USA is used for default value
double defaultCenterLat = 41.850033;
double defaultCenterLng = -87.6500523;
MapType defaultMapType = MapType.normal;
String defaultPinShape = 'circle';
double defaultBearing = 0;
String defaultPinColor = '0xffff0000';
double defaultMapZoom = 4.0;
String pathBuffer = "";
final hexColorRegexFull = RegExp(r'^0x[fF]{2}[a-fA-F0-9]{6}$'); //Full Flutter 8-digit HEX
final hexColorRegexWeb = RegExp(r'^#?[a-fA-F0-9]{6}$'); //Short Web 6-digit HEX

//We can use these functions to do different types of conversions that we normally wouldn't be able to do

String colorToString(Color color) {
  return ("0x${(color.toHexString()).toLowerCase()}");
}

String locationToString(LatLng latLng) {
  String latLngBuffer = latLng.toString();
  latLngBuffer = latLngBuffer.replaceAll("LatLng(", "");
  latLngBuffer = latLngBuffer.replaceAll(")", "");

  return latLngBuffer;
}

LatLng stringToLocation(String string) {
  //You must have LatLng() in the string otherwise you have to use locationToString first
  string = string.replaceAll(RegExp(r'\(|\)'), '');
  string = string.replaceAll(' ', '');
  if (RegExp(
          r'([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?,([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?')
      .hasMatch(string)) {
    List<String> latLngBuffer = string.split(",");
    return LatLng(double.parse(latLngBuffer[0].trim()),
        double.parse(latLngBuffer[1].trim()));
  } else {
    //If something isn't working, let's just return a generic LatLng()
    return const LatLng(640, 640);
  }
}

MapType stringToMapType(String maptype) {
//We're going to use this function to "do a String conversion to MapType"
  switch (maptype) {
    case ("MapType.normal"):
      return MapType.normal;
    case ("MapType.hybrid"):
      return MapType.hybrid;
    case ("MapType.terrain"):
      return MapType.terrain;
    case ("MapType.satellite"):
      return MapType.satellite;
    default:
      return MapType.normal;
  }
}

String mapTypeToString(MapType maptype) {
  switch (mapType) {
    case MapType.normal:
      return "Standard";
    case MapType.hybrid:
      return "Hybrid";
    case MapType.terrain:
      return "Terrain";
    case MapType.satellite:
      return "Satellite";
    default:
      return "N/A";
  }
}

class OdysseyDatabase {
  static final OdysseyDatabase instance = OdysseyDatabase._init();
  static Database? _database;
  OdysseyDatabase._init();

  Future _initDB(String fpath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fpath);
    print(path);
    pathBuffer =
        path; //We wanna use this variable in the initState so that we don't read a dead DB

    return await openDatabase(path,
        version: 2, onCreate: createDB, onUpgrade: upgradeDB);
  }

  Future get database async {
    if (_database != null) return _database!;
    _database = await _initDB('OdysseyDB.db');
    return _database!;
  }

  Future createDB(Database db, int version) async {
    db.execute(
        'CREATE TABLE Pins (id INTEGER, caption TEXT, color TEXT, lat FLOAT, lng FLOAT, date TEXT, location TEXT, shape TEXT, note MEDIUMTEXT, photo LONGBLOB, waypoint INTEGER)');
    db.execute(
        'CREATE TABLE Prefs (mapcenterlat FLOAT, mapcenterlng FLOAT, maplayer TEXT, bearing INT(255), pincolor TEXT, mapzoom INT(255), onboarding TINYINT)');
    db.rawInsert(
        'INSERT INTO Prefs (mapcenterlat, mapcenterlng, maplayer, bearing, pincolor, mapzoom, onboarding) VALUES(?, ?, ?, ?, ?, ?, ?)',
        [
          defaultCenterLat,
          defaultCenterLng,
          defaultMapType.toString(),
          '$defaultBearing',
          defaultPinColor,
          '$defaultMapZoom',
          '1'
        ]);

    print("DB Made!");
    onboarding = 1;
  }

  Future addPinDB(
      int id,
      String caption,
      String date,
      Color color,
      String shape,
      LatLng latLng,
      String location,
      String note,
      Uint8List? photo,
      int? waypoint) async {
    final db = await instance.database;

    double lat = latLng.latitude;
    double lng = latLng.longitude;

    db.rawInsert(
        'INSERT INTO Pins (id, caption, color, lat, lng, date, location, shape, note, photo, waypoint) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          '$id',
          caption,
          colorToString(color),
          '$lat',
          '$lng',
          date,
          location,
          shape,
          note,
          photo,
          waypoint
        ]);
  }

  Future closeDB() async {
    final db = await instance.database;
    db.close();
  }

  Future updatePrefsDB(double mapZoom, double bearing, MapType mt) async {
    final db = await instance.database;
    print(
        "Updating values (Zoom, Bearing, Map Details): $mapZoom, $bearing, $mt");
    /*    We're going to use this function to update all of the rows in Prefs
    Depreciating Center latLng here because we're not using it...
 
    Hijacking the pincolors pref because it's redundant when populateMapfromState assigns the last pin's color as current color
        Since I never thought to assign an ID to prefs because I didn't orgininally think that I needed it, will use the now redundant variable as a mock ID
 */
    db.rawUpdate(
        '''UPDATE Prefs SET mapzoom = ?, bearing = ?, maplayer = ? WHERE pincolor = ?''',
        [mapZoom, bearing, mt.toString(), '0xffff0000']);
  }

  Future updatePinsDB(int id, content, String type) async {
    //What are we updating, it's new contents and what kind it is
    final db = await instance.database;

    switch (type) {
      case "latlng":
        double lat = content.latitude;
        double lng = content.longitude;
        db.rawUpdate('''UPDATE Pins SET lat = ?, lng = ? WHERE id = ?''',
            [lat, lng, id]);
        break;

      case "location":
        db.rawUpdate(
            '''UPDATE Pins SET location = ? WHERE id = ?''', [content, id]);
        break;

      case "caption":
        db.rawUpdate(
            '''UPDATE Pins SET caption = ? WHERE id = ?''', [content, id]);
        break;

      case "note":
        db.rawUpdate(
            '''UPDATE Pins SET note = ? WHERE id = ?''', [content, id]);
        break;

      case "color":
        db.rawUpdate('''UPDATE Pins SET color = ? WHERE id = ?''',
            [colorToString(content), id]);
        break;

      case "shape":
        db.rawUpdate(
            '''UPDATE Pins SET shape = ? WHERE id = ?''', [content, id]);
        break;

      case "photo":
        db.rawUpdate(
            '''UPDATE Pins SET photo = ? WHERE id = ?''', [content, id]);
        break;

      case "waypoint":
        //We Need To Rebalance The Test Of The Waypoint IDs
        db.rawUpdate(
            '''UPDATE Pins SET waypoint = ? WHERE id = ?''', [content, id]);
        break;
    }
  }

  Future initStatefromDB() async {
/*     Let's using this function to fill up the map and Journal when booting the app
    Is using all these variables the way that I am the smartest way to do it?
    Probably not but I'll figure something out later maybe type type-casting is the right way to go */
    final db = await instance.database;

    if (pathBuffer != "") {
      //Load Prefs Data
      List<Map<String, dynamic>> prefsdbResults = await db.query("Prefs");
      mapZoom =
          double.tryParse(prefsdbResults[0]['mapzoom']?.toString() ?? '') ??
              defaultMapZoom;
      mapType = stringToMapType(prefsdbResults[0]['maplayer']?.toString() ??
          defaultMapType.toString());
      bearing =
          double.tryParse(prefsdbResults[0]['bearing']?.toString() ?? '') ??
              defaultBearing;

      //Load User Data
      List<Map<String, dynamic>> pinsdbResults = await db.query("Pins");
      if (pinsdbResults.isEmpty) return;

      List<Map<String, dynamic>> waypointCounterBuffer =
          await db.query("Pins", columns: ["MAX(waypoint)"]);
      if (waypointCounterBuffer.isNotEmpty) {
        waypointCounter = int.tryParse(
                waypointCounterBuffer[0]['MAX(waypoint)']?.toString() ?? '0') ??
            0;
      }

      pinCounter = pinsdbResults.length;

/*    This part is the star of the show, we are parsing everything from the Pins DB
      Then by counter  we are attempting, one by one to place everything on the map */
      for (int i = 0; i <= pinCounter - 1; i++) {
        //Parse the Pin's Color
        //If for whatever reason there is an issue parsing the color HEX...

        if ((!hexColorRegexFull
            .hasMatch(pinsdbResults[i]["color"].toString()))) {
          print("Error With Pin: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");
          await db.rawUpdate('''UPDATE Pins SET color = ? WHERE id = ?''',
              [defaultPinColor, i + 1]);
        }

        pincolor = Color(int.tryParse(pinsdbResults[i]["color"].toString()) ??
            int.parse(defaultPinColor));

        //Parse the Pin's Lat and Lng
        LatLng latLng = const LatLng(0, 0);
        if (double.tryParse(pinsdbResults[i]["lat"].toString()) == null ||
            double.tryParse(pinsdbResults[i]["lng"].toString()) == null) {
          //If we run into an issue or something else, let's just not display the pin...

          print("Error With Pin: ${i + 1}");
          print(
              "We're going to need to fix it otherwise we will run into issues...");

          await db.rawUpdate(
              '''UPDATE Pins SET lat = ?, lng = ? WHERE id = ?''',
              [0.0, 0.0, i + 1]);
        } else {
          latLng = LatLng(
              double.tryParse(pinsdbResults[i]["lat"].toString()) ?? 0.0,
              double.tryParse(pinsdbResults[i]["lng"].toString()) ?? 0.0);
        }

        pins.add(PinData(
            pinid: i,
            pincolor: pincolor,
            pincoor: latLng,
            pindate: pinsdbResults[i]["date"].toString(),
            pinnote: pinsdbResults[i]["note"].toString(),
            pincaption: pinsdbResults[i]["caption"].toString(),
            pinshape: pinsdbResults[i]["shape"].toString(),
            pinlocation: pinsdbResults[i]["location"].toString(),
            pinphoto: pinsdbResults[i]["photo"],
            pinwaypoint: pinsdbResults[i]["waypoint"]));
      }
    } else {
      print("Empty/No DB, Skipping...");
    }
  }

  Future initDBfromState() async {
    clearPinsDB(); //We need to clean out the existing DB and reappend it
    for (int i = 0; i < pins.length; i++) {
      addPinDB(
          i + 1,
          pins[i].pincaption ?? "",
          pins[i].pindate ?? "",
          pins[i].pincolor,
          pins[i].pinshape,
          pins[i].pincoor,
          pins[i].pinlocation,
          pins[i].pinnote ?? "",
          pins[i].pinphoto,
          pins[i].pinwaypoint);
    }
  }

  Future resetDB() async {
    final db = await instance.database;
    db.delete("Pins");
    db.delete("Prefs");
    db.rawInsert(
        'INSERT INTO Prefs (mapcenter, maplayer, bearing, pincolor, zoom) VALUES(?, ?, ?, ?, ?, ?)',
        [
          defaultCenterLat,
          defaultCenterLng,
          defaultMapType,
          '$defaultBearing',
          defaultPinColor,
          '$defaultMapZoom'
        ]);
  }

  void upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      switch (oldVersion) {
        //If DB version is version 1, it needs to pick up ALL the newer changes, not just the latest ones
        case 1:
          print("Updating DB to Version 2...");
          //Version 2 Changes
          db.execute(
              "ALTER TABLE Pins ADD COLUMN shape TEXT DEFAULT '$defaultPinShape' NOT NULL;");
          db.execute(
              "ALTER TABLE Pins ADD COLUMN note MEDIUMTEXT DEFAULT '' NOT NULL;");
          db.execute("ALTER TABLE Pins ADD COLUMN photo LONGBLOB;");
          db.execute("ALTER TABLE Pins ADD COLUMN waypoint INTEGER;");
          db.execute(
              "ALTER TABLE Prefs ADD COLUMN onboarding TINYINT DEFAULT '1' NOT NULL;");
          print("Update Complete.");
          break;
        default:
          print("No changes made to DB...");
          break;
      }
    }
  }

  Future deletePinDB(int id) async {
    final db = await instance.database;
    db.query("Pins");
    db.execute("DELETE FROM Pins WHERE id = $id");
  }

  Future clearPinsDB() async {
    final db = await instance.database;
    db.delete("Pins");
  }

  Future clearWaypointsDB() async {
    final db = await instance.database;
    db.execute("ALTER TABLE Pins DROP COLUMN waypoint");
    db.execute("ALTER TABLE Pins ADD COLUMN waypoint INTEGER;");
  }

  Future clearPhotosDB() async {
    final db = await instance.database;
    db.execute("ALTER TABLE Pins DROP COLUMN photo");
    db.execute("ALTER TABLE Pins ADD COLUMN photo LONGBLOB;");
  }
}

//This code will be reserved for a future version of Odyssey for the Web
class OdysseyDatabaseWeb {
  static final OdysseyDatabaseWeb instance = OdysseyDatabaseWeb._init();
  OdysseyDatabaseWeb._init();

  Future initStatefromDB() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    mapZoom = prefs.getDouble("mapZoom") ?? defaultMapZoom;
    mapType = stringToMapType(
        prefs.getString("mapType") ?? defaultMapType.toString());
    bearing = prefs.getDouble("bearing") ?? defaultBearing;

    pinCounter = prefs.getInt("counter") ?? pinCounter;

    pinCounter = 1;

    for (int i = 0; i <= pinCounter - 1; i++) {
      pincolor = Color(
          int.tryParse(prefs.getStringList("pin_$i")?[2] ?? defaultPinColor) ??
              int.parse(defaultPinColor));

      LatLng latLng = LatLng(
          double.tryParse(
                  prefs.getStringList("pin_$i")?[2].toString() ?? "0.0") ??
              0.0,
          double.tryParse(
                  prefs.getStringList("pin_$i")?[2].toString() ?? "0.0") ??
              0.0);

      pins.add(PinData(
          pinid: i,
          pincolor: pincolor,
          pincoor: latLng,
          pindate: prefs.getStringList("pin_$i")?[1].toString(),
          pinnote: prefs.getStringList("pin_$i")?[8].toString(),
          pincaption: prefs.getStringList("pin_$i")?[9].toString(),
          pinshape:
              prefs.getStringList("pin_$i")?[1].toString() ?? defaultPinShape,
          pinlocation:
              prefs.getStringList("pin_$i")?[6].toString() ?? "Location N/A",
          //pinphoto: Uint8List(int.tryParse(prefs.getStringList("pin_$i")?[7].toString())),
          pinwaypoint: int.tryParse(
                  prefs.getStringList("pin_$i")?[2].toString() ?? "0") ??
              0));
    }
  }

  Future updatePrefsDB(double mapZoom, double bearing, MapType mt) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble("mapZoom", mapZoom);
    prefs.setDouble("bearing", bearing);
    prefs.setString("mapType", mt.toString());
  }

  Future addPinDB(
      int id,
      String caption,
      String date,
      Color color,
      String shape,
      LatLng latLng,
      String location,
      String note,
      Uint8List? photo,
      int? waypoint) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    double lat = latLng.latitude;
    double lng = latLng.longitude;

    prefs.setStringList('pin_$id', [
      caption,
      date,
      colorToString(color),
      '$lat',
      '$lng',
      shape,
      location,
      note,
      photo.toString(),
      waypoint.toString()
    ]);
  }

  Future deletePinDB(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('pin_$id');
  }

  Future clearPinsDB() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
