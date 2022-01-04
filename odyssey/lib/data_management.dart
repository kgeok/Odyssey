// ignore_for_file: avoid_print
import 'package:sqflite/sqflite.dart';

const dbName = 'OdysseyData.db';
late Database db;

Future<Database> get database async {
  if (db != null) return db;
  // if _database is null we instantiate it
  db = await openDB();
  return db;
}

Future openDB() async {
  return await openDatabase(
    dbName,
    version: 3,
    onCreate: (db, int version) async {
      db.execute(
          //TODO: change LatLng back to float from text and date to date from TEXT
          'CREATE TABLE Pins (id INTEGER, caption TEXT, color TEXT, lat TEXT, lng TEXT, date TEXT, location TEXT)');
      db.execute(
          'CREATE TABLE Prefs (mapcenter TEXT, maplayer TEXT, bearing INT(255), pincolor TEXT, zoom INT(255))');
      db.rawInsert(
          'INSERT INTO Prefs (mapcenter, maplayer, bearing, pincolor, zoom) VALUES(?, ?, ?, ?, ?)',
          [
            'LatLng(41.850033, -87.6500523);',
            'MapType.normal',
            0,
            '0xffff0000',
            '4'
          ]);

      print("DB Made!");
      testDB(db);
    },
  );
}

void clearDB() async {
  deleteDatabase('OdysseyData.db');
  openDB();
}

void testDB(db) async {
  print(db.toString());
  print(db.query('Pins'));
  print(db.query('Prefs'));
}

//Sample: addPinDB(1, "Test", "Test", "Test", "Test", "test");

void addPinDB(id, caption, color, latLng, date, location) async {
  id = id.toString();
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

void removePinDB(db, id) {}
