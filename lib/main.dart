import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Anxy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Anxy'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = [];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice? _connectedDevice;
  int? _heartRate;

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    print("ERROR");
                    print(e);
                    // if (e.already_connected) {
                    //   return;
                    // }
                    // if (e.code != 'already_connected') {
                    // throw e;
                    // }
                  } finally {
                    List<BluetoothService> services =
                        await device.discoverServices();
                    for (BluetoothService service in services) {
                      if (service.uuid.toString() ==
                          "0000180d-0000-1000-8000-00805f9b34fb") {
                        for (BluetoothCharacteristic characteristic
                            in service.characteristics) {
                          var isHeartRateCharacteristic =
                              characteristic.uuid.toString() ==
                                      "00002a37-0000-1000-8000-00805f9b34fb" &&
                                  characteristic.properties.notify;
                          if (isHeartRateCharacteristic) {
                            characteristic.value.listen((value) {
                              setState(() {
                                _heartRate = value[1];
                              });
                              print(value);
                            });
                            await characteristic.setNotifyValue(true);
                          }
                        }
                      }
                    }
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  Widget _buildMonitorView() {
    var heartRate = '';
    if (_heartRate != null) {
      heartRate = _heartRate.toString();
    }
    return new Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          heartRate,
          style: TextStyle(fontSize: 100),
        ),
      ],
    ));
  }

  Widget _buildView() {
    if (_connectedDevice != null) {
      return _buildMonitorView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}
