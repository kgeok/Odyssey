// ignore_for_file: avoid_print
import 'package:path/path.dart';
import 'package:odyssey/main.dart';
import 'package:sqflite/sqflite.dart';

//These are the default value we use for settings

var defaultCenter = 'LatLng(41.850033, -87.6500523)';
var defaultMapType = 'MapType.normal';
var defaultBearing = 0;
var defaultPinColor = '0xffff0000';
var defaultMapZoom = 4;

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    db.execute(
        //TODO: change LatLng back to float from text and date to date from TEXT
        'CREATE TABLE Pins (id INTEGER, caption TEXT, color TEXT, lat TEXT, lng TEXT, date TEXT, location TEXT)');
    db.execute(
        'CREATE TABLE Prefs (mapcenter TEXT, maplayer TEXT, bearing INT(255), pincolor TEXT, zoom INT(255))');
    db.rawInsert(
        'INSERT INTO Prefs (mapcenter, maplayer, bearing, pincolor, zoom) VALUES(?, ?, ?, ?, ?)',
        [
          defaultCenter,
          defaultMapType,
          '$defaultBearing',
          defaultPinColor,
          '$defaultMapZoom'
        ]);

    print("DB Made!");
  }

  Future addPinDB(id, caption, color, latLng, date, location) async {
    final db = await instance.database;

    caption = caption.toString();
    color.toString();
    date.toString();
    location.toString();

    db.rawInsert(
        'INSERT INTO Pins (id, caption, color, lat, lng, date, location) VALUES(?, ?, ?, ?, ?, ?, ?)',
        [
          '$id',
          '$caption',
          '$color',
          '$latLng',
          '$latLng',
          '$date',
          '$location'
        ]);
  }

  Future closeDB() async {
    final db = await instance.database;
    db.close();
  }

  Future initStatefromDB() async {
    //Let's using this function to fill up the map and Journal when booting the app
    final db = await instance.database;
    var counterBuffer = await db.query("Pins", columns: ["MAX(id)"]);
    var counter = int.parse(counterBuffer[0]['MAX(id)'].toString());
    // var pinColorBuffer = await db.query("Prefs"); //We're going to extract the PinColor from Prefs instead of using the defualt variable

    print(counter);
    pinCounter = counter;
    for (var i = 1; i <= counter; i++) {
      //parse the pin color

      //parse the caption
      captionBuffer = await db.query("Pins", columns: ["caption"]);
      caption = captionBuffer[0]["caption"].toString();
      print(caption);

      //

      //appendMarker();

    }
  }

  Future resetDB() async {
    final db = await instance.database;
    db.delete("Pins");
    db.delete("Prefs");
    db.rawInsert(
        'INSERT INTO Prefs (mapcenter, maplayer, bearing, pincolor, zoom) VALUES(?, ?, ?, ?, ?)',
        [
          defaultCenter,
          defaultMapType,
          '$defaultBearing',
          defaultPinColor,
          '$defaultMapZoom'
        ]);
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
