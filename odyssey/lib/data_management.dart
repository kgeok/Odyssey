// ignore_for_file: avoid_print, unused_local_variable, prefer_typing_uninitialized_variables, depend_on_referenced_packages
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

//These are the default value we use for settings
//These will also be the values to fall back on in case DB can't be loaded
//They will also be loaded into DB on init

var defaultCenterLat = 41.850033;
var defaultCenterLng = -87.6500523;
var defaultMapType = MapType.normal;
var defaultPinShape = 'circle';
double defaultBearing = 0;
var defaultPinColor = '0xffff0000';
String defaultShape = 'circle';
double defaultMapZoom = 4.0;
var pathBuffer;

class OdysseyDatabase {
  static final OdysseyDatabase instance = OdysseyDatabase._init();

  static Database? _database;

  OdysseyDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('OdysseyDB.db');
    return _database!;
  }

  Future<Database> _initDB(String fpath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fpath);
    print(path);
    pathBuffer =
        path; //We wanna use this variable in the initState so that we don't read a dead DB

    return await openDatabase(path,
        version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
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
      id, caption, date, color, shape, latLng, location, note) async {
    final db = await instance.database;

    caption = caption.toString();
    var colorBuffer = color.toString();
    colorBuffer = colorBuffer.replaceAll("Color(", "");
    colorBuffer = colorBuffer.replaceAll(")", "");

    //split latlng and make it a two parter float

    var latLngBuffer = latLng.toString();
    latLngBuffer = latLngBuffer.replaceAll("LatLng(", "");
    latLngBuffer = latLngBuffer.replaceAll(")", "");
    var latLngBuffer2 = latLngBuffer.split(", ");
    var lat = double.parse(latLngBuffer2[0].trim());
    var lng = double.parse(latLngBuffer2[1].trim());

    location.toString();

    db.rawInsert(
        'INSERT INTO Pins (id, caption, color, lat, lng, date, location, shape, note) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          '$id',
          '$caption',
          colorBuffer,
          '$lat',
          '$lng',
          date,
          '$location',
          '$shape',
          '$note'
        ]);
  }

  Future closeDB() async {
    final db = await instance.database;
    db.close();
  }

  Future updatePrefsDB(mapZoom, bearing, latLng, mt) async {
    final db = await instance.database;

    //split latlng and make it a two parter float

    var latLngBuffer = latLng.toString();
    latLngBuffer = latLngBuffer.replaceAll("LatLng(", "");
    latLngBuffer = latLngBuffer.replaceAll(")", "");
    var latLngBuffer2 = latLngBuffer.split(", ");
    var lat = double.parse(latLngBuffer2[0].trim());
    var lng = double.parse(latLngBuffer2[1].trim());

    /* Hijacking the pincolors pref because it's redundant when populateMapfromState assigns the last pin's color as current color
        Since I never thought to assign an ID to prefs because I didn't orgininally think that I needed it, will use the now redundant variable as a mock ID */

    db.rawUpdate(
        '''UPDATE Prefs SET mapzoom = ?, bearing = ?, mapcenterlat = ?, mapcenterlng = ?, maplayer = ? WHERE pincolor = ?''',
        [mapZoom, bearing, lat, lng, mt.toString(), '0xffff0000']);
  }

  Future initStatefromDB() async {
    //Let's using this function to fill up the map and Journal when booting the app
    //Is using all these variables the way that I am the smartest way to do it?
    //Probably not but I'll figure something out later maybe type type-casting is the right way to go
    final db = await instance.database;

    if (pathBuffer != null) {
      //Load Prefs Data

      var mapZoomBuffer = await db.query("Prefs", columns: ["mapzoom"]);
      mapZoom = double.parse(mapZoomBuffer[0]['mapzoom'].toString());

      var mapTypeBuffer = await db.query("Prefs", columns: ["maplayer"]);
      mapTypeHandler(mapTypeBuffer[0]['maplayer'].toString());
      //mapType = mapTypeBuffer[0]['maplayer'].toString() as MapType; //Tried casting this one didn't work...

      var bearingBuffer = await db.query("Prefs", columns: ["bearing"]);
      bearing = double.parse(bearingBuffer[0]['bearing'].toString());

      //Load User Data
      var counterBuffer = await db.query("Pins", columns: ["MAX(id)"]);
      var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
      var colorBuffer = await db.query("Pins", columns: ["color"]);

      counter ??= 0;

      pinCounter = counter;
      //This part is the star of the show, we are parsing everything from the Pins DB
      //Then by counter we are attempting, one by one to place everything on the map
      for (var i = 0; i <= counter - 1; i++) {
        //Parse the Pin's Color
        var colorBuffer2 = colorBuffer[i]["color"].toString();
        pincolor = Color(int.parse(colorBuffer2));

        //Parse the Caption
        captionBuffer = await db.query("Pins", columns: ["caption"]);
        caption = captionBuffer[i]["caption"].toString();

        //Parse the Location

        //We can't reuse locationBuffer because we can't assign it an array
        var locationBuffer2 = await db.query("Pins", columns: ["location"]);
        var location = locationBuffer2[i]["location"].toString();

        //Parse the Pin's date
        var dateBuffer = await db.query("Pins", columns: ["date"]);
        var date = dateBuffer[i]["date"].toString();

        //Parse the Pin's note
        var noteBuffer = await db.query("Pins", columns: ["note"]);
        var note = noteBuffer[i]["note"].toString();

        //Parse the Pin's shape
        var shapeBuffer = await db.query("Pins", columns: ["shape"]);
        var shape = shapeBuffer[i]["shape"].toString();

        //Parse the Pin's Lat and Lng
        var locationBufferlat = await db.query("Pins", columns: ["lat"]);
        var locationBufferlng = await db.query("Pins", columns: ["lng"]);
        LatLng latLng = LatLng(
            double.parse(locationBufferlat[i]["lat"].toString()),
            double.parse(locationBufferlng[i]["lng"].toString()));

        pins.add(PinData(
            pinid: i,
            pincolor: pincolor,
            pincoor: latLng,
            pindate: date,
            pinnote: note,
            pincaption: caption,
            pinshape: shape,
            pinlocation: location));
      }
    } else {
      print("Empty/No DB, Skipping...");
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

  void _upgradeDB(Database db, int oldVersion, int newVersion) async {
    //This is for upgrading from 1.0 to 1.1 and future updates
    if (oldVersion < newVersion) {
      print("Updating DB...");
      db.execute(
          "ALTER TABLE Pins ADD COLUMN shape TEXT DEFAULT 'circle' NOT NULL;");
      db.execute(
          "ALTER TABLE Pins ADD COLUMN note MEDIUMTEXT DEFAULT '' NOT NULL;");
      db.execute("ALTER TABLE Pins ADD COLUMN photo LONGBLOB;");
      db.execute("ALTER TABLE Pins ADD COLUMN waypoint INTEGER;");
      db.execute(
          "ALTER TABLE Prefs ADD COLUMN onboarding TINYINT DEFAULT '1' NOT NULL;");
    }
  }

  Future deletePinDB(id) async {
    final db = await instance.database;
    db.query("Pins");
    db.execute("DELETE FROM Pins WHERE id = $id");
  }

  Future clearPinsDB() async {
    final db = await instance.database;
    db.delete("Pins");
  }
}

void mapTypeHandler(String mt) {
//We're going to use this function to "do a String conversion to MapType"
  switch (mt) {
    case ("MapType.normal"):
      mapType = MapType.normal;
      break;

    case ("MapType.hybrid"):
      mapType = MapType.hybrid;
      break;

    case ("MapType.terrain"):
      mapType = MapType.terrain;
      break;

    case ("MapType.satellite"):
      mapType = MapType.satellite;
      break;

    default:
      mapType = MapType.normal;
      break;
  }
  print(mapType);
}
