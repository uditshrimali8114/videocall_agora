import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/services.dart';
import 'package:videocall_agora/utils/conts.dart';
import 'package:path/path.dart' as path;

class CallPage extends StatefulWidget {
  final String channelName;
  final String appId;
  final String token;
  final ClientRole role;

  const CallPage({Key? key, required this.channelName, required this.role, required this.appId, required this.token})
      : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infostrings = <String>[];
  bool muted = false;
  bool viewPanel = false;
  bool _isEnabledVirtualBackgroundImage = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  Future<void> initialize() async {
    if (widget.appId.isEmpty) {
      setState(() {
        _infostrings.add('AppId Missing');
        _infostrings.add("agora Engine is not starting");
      });
      return;
    }
    _engine = await RtcEngine.create(appId01);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);

    _addAgoraEventHandler();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = const VideoDimensions(width: 350, height: 500);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(widget.token, widget.channelName, null, 0);
    // _enableVirtualBackground();
  }

  Future<void> _enableVirtualBackground() async {
    ByteData data = await rootBundle.load("assets/bg.jpg");
    List<int> bytes =
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String p = path.join(appDocDir.path, 'agora-logo.png');
    final file = File(p);
    if (!(await file.exists())) {
      await file.create();
      await file.writeAsBytes(bytes);
    }

    await _engine.enableVirtualBackground(
        !_isEnabledVirtualBackgroundImage,
        VirtualBackgroundSource(
            backgroundSourceType: VirtualBackgroundSourceType.Img, source: p));
    setState(() {
      _isEnabledVirtualBackgroundImage = !_isEnabledVirtualBackgroundImage;
    });
    _engine.playEffect(15, "asknc", 2, 2.5, 2.5, 3, true);
  }

  void _addAgoraEventHandler() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'error $code';
        _infostrings.add(info);
      });
    }, joinChannelSuccess: (channel, uid, elepsed) {
      setState(() {
        final info = 'joinChannel: $channel, uid : $uid';
        _infostrings.add(info);
      });
    },
    leaveChannel: (stats){
      setState(() {
        const info = 'leaveChannel';
        _infostrings.add(info);
      });
      _users.clear();
    },
      userJoined: (uid, elepsed){
      setState(() {
        _infostrings.add('User Joined $uid');
        _users.add(uid);
      });
      },
      userOffline: (uid,elepsed){
      setState(() {
        _infostrings.add('User Offline $uid');
        _users.remove(uid);
      });
    },
      firstRemoteVideoFrame: (uid,width,height,elepsed){
      setState(() {
        _infostrings.add("First Remote Video $uid, $height x $width");
      });
      }
    ));
  }

  Widget _viewRows(){
    final List<StatefulWidget> list = [];
    if(widget.role == ClientRole.Broadcaster){
      list.add(const rtc_local_view.SurfaceView());
    }
    for(var uid in _users){
      list.add(rtc_remote_view.SurfaceView(uid: uid, channelId: widget.channelName));
    }
    final views = list;
    return Column(
      children: List.generate(views.length, (index) => Expanded(child: views[index])),
    );
  }

  Widget _toolBar(){
    if(widget.role == ClientRole.Audience) return const SizedBox();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:<Widget>[
          RawMaterialButton(
            padding: const EdgeInsets.all(12),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: muted? Colors.blueAccent:Colors.white,
              onPressed: (){
            setState(() {
              muted = !muted;
            });
            _engine.muteLocalAudioStream(muted);

          },
              child: Icon(muted?Icons.mic_off:Icons.mic,color: muted? Colors.white:Colors.blueAccent,size: 20,)),
          RawMaterialButton(
              padding: const EdgeInsets.all(15),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              onPressed: ()=>Navigator.pop(context),
              child: const Icon(Icons.call_end,color: Colors.white,size: 20,)),
          RawMaterialButton(
              padding: const EdgeInsets.all(12),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              onPressed: (){
               _engine.switchCamera();

              },
              child: const Icon(Icons.switch_camera,color:Colors.blueAccent,size: 20,)),
          RawMaterialButton(
              padding: const EdgeInsets.all(12),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor:Colors.transparent,
              onPressed: (){
                _enableVirtualBackground();
               // setState(() {
               //   _isEnabledVirtualBackgroundImage = true;
               // });

              },
              child: const Icon(Icons.ac_unit_outlined,color:Colors.blueAccent,size: 20,)),
        ],
      ),
    );
  }

  Widget _panel(){
    return Visibility(
        visible: viewPanel,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical:48 ),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical:48 ),
              child: ListView.builder(
                  reverse: true,
                  itemCount: _infostrings.length,
                  itemBuilder: (BuildContext context, int index){
                    if(_infostrings.isEmpty){
                      return const Text("null");
                    }
                    return Padding(padding: const EdgeInsets.symmetric(vertical: 3,horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2,horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(_infostrings[index]),
                        ))
                      ],
                    ),
                    );
                  }),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("VideoCall"),
        actions: [
          IconButton(onPressed: (){
            setState(() {
              viewPanel = !viewPanel;
            });
          }, icon: const Icon(Icons.info_outline))
        ],
      ),
      body: Center(
        child: Stack(
          children: [
            _viewRows(),
            _panel(),
            _toolBar(),
          ],
        ),
      ),
    );
  }
}
