import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ntp/ntp.dart';
import 'package:sensors/sensors.dart';
import 'package:flutter/foundation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AccelerometerEvent accelData;
  String text = "No one bumping near you";
  int ntpOffset = 0;

  /// Shake detection threshold
  final double shakeThresholdGravity = 1.8;

  /// Minimum time between shake
  final int shakeSlopTimeMS = 500;

  /// Time before shake count resets
  final int shakeCountResetTime = 3000;

  int mShakeTimestamp = DateTime.now().millisecondsSinceEpoch;

  String name = "";

  @override
  void initState() {
    super.initState();
    DateTime startDate = DateTime.now().toLocal();
    NTP
        .getNtpOffset(lookUpAddress: "0.uk.pool.ntp.org", localTime: startDate)
        .then((offset) {
      setState(() {
        ntpOffset = offset;
      });
    });
  }

  Future<List<dynamic>> detectBump(AccelerometerEvent event) async {
    dynamic empty = [];
    if (name == "") {
      return Future.value(empty);
    }
    double x = event.x;
    double y = event.y;
    double z = event.z;

    double gX = x / 9.80665;
    double gY = y / 9.80665;
    double gZ = z / 9.80665;

    // gForce will be close to 1 when there is no movement.
    double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    if (gForce > shakeThresholdGravity) {
      debugPrint("G force detected");
      var now = DateTime.now().millisecondsSinceEpoch;
      // ignore shake events too close to each other (500ms)
      if (mShakeTimestamp + shakeSlopTimeMS > now) {
        return Future.value(empty);
      }

      mShakeTimestamp = now;
      return Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .then((pos) => Dio().post(
                  "https://s44imfmtqg.execute-api.us-east-1.amazonaws.com/dev/users",
                  data: {
                    "name": name,
                    "lat": pos.latitude,
                    "long": pos.longitude,
                    "bump_time": DateTime.now()
                        .toLocal()
                        .add(Duration(milliseconds: ntpOffset))
                        .millisecondsSinceEpoch
                  }))
          .then((res) => (res.data as List));
    }
    return Future.value(empty);
  }

  @override
  Widget build(BuildContext context) {
    accelerometerEvents.listen((AccelerometerEvent event) {
      detectBump(event).then((nearbyUsers) {
        if (nearbyUsers.isEmpty) {
          return;
        }
        for (var user in nearbyUsers) {
          setState(() {
            text = "Bumped with ${user['name']}";
          });
        }
      });
    });

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              text,
            ),
          TextField(
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "What's your name?"
            ),
            onChanged: (text) => this.setState(() => name = text),
          )
          ],
        ),
      ),
    );
  }
}
