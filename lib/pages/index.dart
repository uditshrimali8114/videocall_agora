import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:videocall_agora/utils/conts.dart';
import 'call.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // bool success =  FlutterBackground.initialize(androidConfig: androidConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VideoCall'),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              const SizedBox(
                height: 80,
              ),
              TextField(
                controller: _channelController,
                decoration: const InputDecoration(
                  labelText: 'Enter Channel name',
                  // use the getter variable defined above
                  errorText: "Enter Channel Name",
                ),
              ),
              ElevatedButton(
                  onPressed: () => onJoin(appId01, channelName01, token01),
                  child: const Text("Channel 01 Join now")),
              ElevatedButton(
                  onPressed: () => onJoin(appId02, channelName02, token02),
                  child: const Text("Channel 02 Join now")),
              ElevatedButton(
                  onPressed: () => onJoin(appId03, channelName03, token03),
                  child: const Text("Channel 03 Join now")),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onJoin(appId, channelName, token) async {
    await handleCameraAndMic(Permission.camera).then((value) {
      handleCameraAndMic(Permission.microphone).then((value) => {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CallPage(
                          channelName: channelName,
                          role: ClientRole.Broadcaster,
                          appId: appId,
                          token: token,
                        )))
          });
    });
  }
}

Future<void> handleCameraAndMic(Permission permission) async {}
