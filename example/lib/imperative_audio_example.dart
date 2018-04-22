import 'package:flutter/material.dart';
import 'package:fluttery_audio/fluttery_audio.dart';
import 'package:meta/meta.dart';

class ImperativeAudioExample extends StatefulWidget {

  final String audioUrl;

  ImperativeAudioExample({
    @required this.audioUrl,
  });

  @override
  _ImperativeAudioExampleState createState() => new _ImperativeAudioExampleState();
}

class _ImperativeAudioExampleState extends State<ImperativeAudioExample> {
  AudioPlayer audioPlayer;
  Duration audioLength;
  Duration position;

  @override
  initState() {
    super.initState();

    audioPlayer = FlutteryAudio.audioPlayer();
    audioPlayer.addListener(
        onAudioLengthChanged: (Duration audioLength) {
          setState(() {
            this.audioLength = audioLength;
          });
        },
        onPlayerPlaybackUpdate: (Duration position) {
          setState(() {
            this.position = position;
          });
        }
    );
  }

  Widget _buildButton(String title, VoidCallback onPressed) {
    return new Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: new RaisedButton(
        child: new Text(
          title,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        _buildButton('LOAD AUDIO', () {
          audioPlayer.loadMedia(Uri.parse(widget.audioUrl));
        }),
        _buildButton('PLAY AUDIO', () {
          audioPlayer.play();
        }),
        _buildButton('PAUSE AUDIO', () {
          audioPlayer.pause();
        }),
        _buildButton('STOP AUDIO', () {
          audioPlayer.stop();
        }),
        new Slider(
            value: position == null ? 0.0 : position.inMilliseconds.toDouble(),
            max: audioLength == null ? 1.0 : audioLength.inMilliseconds.toDouble(),
            onChanged: (double newValue) {

            }
        ),
      ],
    );
  }
}
