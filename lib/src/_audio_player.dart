import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = new Logger('AudioPlayer');

class AudioPlayer {

  final String playerId;
  final MethodChannel channel;
  final Set<Function(AudioPlayerState)> _onStateChangeds = new Set();
  final Set<Function(Duration)> _onAudioLengthChangeds = new Set();
  final Set<Function> _onAudioLoadings = new Set();
  final Set<Function(int)> _onBufferingUpdates = new Set();
  final Set<Function> _onAudioReadys = new Set();
  final Set<Function> _onPlayerPlayings = new Set();
  final Set<Function(Duration)> _onPlayerPositionChangeds = new Set();
  final Set<Function> _onPlayerPauseds = new Set();
  final Set<Function> _onPlayerStoppeds = new Set();
  final Set<Function> _onPlayerCompleteds = new Set();
  final Set<Function> _onSeekStarteds = new Set();
  final Set<Function> _onSeekCompleteds = new Set();
  AudioPlayerState _state;
  Duration _audioLength;
  int _bufferedPercent;
  Duration _position;

  AudioPlayer({
    this.playerId,
    this.channel,
  }) {
    // TODO: ask channel for initial state so that Flutter can connect to
    // TODO: existing AudioPlayers
    _setState(AudioPlayerState.idle);

    channel.setMethodCallHandler((MethodCall call) {
      print('Received channel message: ${call.method}');
      switch (call.method) {
        case "onAudioLoading":
          _log.fine('onAudioLoading');

          // If new audio is loading then we have no playhead position and we
          // don't know the audio length.
          _setAudioLength(null);
          _setPosition(null);

          _setState(AudioPlayerState.loading);

          for (Function callback in _onAudioLoadings) {
            callback();
          }
          break;
        case "onBufferingUpdate":
          _log.fine('onBufferingUpdate');

          final percent = call.arguments['percent'];
          _setBufferedPercent(percent);

          break;
        case "onAudioReady":
          _log.fine('onAudioReady');
          _log.fine('for real');
          _log.fine('${call.arguments['audioLength']}');

          // When audio is ready then we get passed the length of the clip.
          final audioLengthInMillis = call.arguments['audioLength'];
          _setAudioLength(new Duration(milliseconds: audioLengthInMillis));

          // When audio is ready then the playhead is at zero and we're paused.
          _setPosition(const Duration(milliseconds: 0));
          _log.fine("Setting state to paused");
          _setState(AudioPlayerState.paused);

          for (Function callback in _onAudioReadys) {
            callback(callback);
          }
          break;
        case "onPlayerPlaying":
          _log.fine('onPlayerPlaying');

          _setState(AudioPlayerState.playing);

          for (Function callback in _onPlayerPlayings) {
            callback();
          }
          break;
        case "onPlayerPlaybackUpdate":
          _log.fine('onPlayerPlaybackUpdate');

          // The playhead has moved, update our playhead position reference.
          _setPosition(new Duration(milliseconds: call.arguments['position']));
          break;
        case "onPlayerPaused":
          _log.fine('onPlayerPaused');

          _setState(AudioPlayerState.paused);

          for (Function callback in _onPlayerPauseds) {
            callback();
          }
          break;
        case "onPlayerStopped":
          _log.fine('onPlayerStopped');

          // When we are stopped it means more than just paused. The audio will
          // have to be reloaded. Therefore, we no longer have a playhead
          // position or audio length.
          _setAudioLength(null);
          _setPosition(null);

          _setState(AudioPlayerState.stopped);

          for (Function callback in _onPlayerStoppeds) {
            callback();
          }
          break;
        case "onPlayerCompleted":
          _log.fine('onPlayerCompleted');

          _setState(AudioPlayerState.completed);

          for (Function callback in _onPlayerCompleteds) {
            callback();
          }
          break;
        case "onSeekStarted":
          for (Function callback in _onSeekStarteds) {
            callback();
          }
          break;
        case "onSeekCompleted":
          for (Function callback in _onSeekCompleteds) {
            callback();
          }
          break;
      }
    });
  }

  void dispose() {
    _onStateChangeds.clear();
    _onAudioLengthChangeds.clear();
    _onAudioLoadings.clear();
    _onBufferingUpdates.clear();
    _onAudioReadys.clear();
    _onPlayerPlayings.clear();
    _onPlayerPositionChangeds.clear();
    _onPlayerPauseds.clear();
    _onPlayerStoppeds.clear();
    _onPlayerCompleteds.clear();
    _onSeekStarteds.clear();
    _onSeekCompleteds.clear();
  }

  get state => _state;

  _setState(AudioPlayerState state) {
    _state = state;

    for (Function callback in _onStateChangeds) {
      callback(state);
    }
  }

  /// Length of the loaded audio clip.
  ///
  /// Accessing [audioLength] is only valid after the [AudioPlayer] has loaded
  /// an audio clip and before the [AudioPlayer] is stopped.
  get audioLength => _audioLength;

  _setAudioLength(Duration audioLength) {
    _audioLength = audioLength;

    for (Function callback in _onAudioLengthChangeds) {
      callback(_audioLength);
    }
  }

  get bufferedPercent => _bufferedPercent;

  _setBufferedPercent(int percent) {
    _bufferedPercent = percent;

    for (Function callback in _onBufferingUpdates) {
      callback(_bufferedPercent);
    }
  }

  /// Current playhead position of the [AudioPlayer].
  ///
  /// Accessing [position] is only valid after the [AudioPlayer] has loaded
  /// an audio clip and before the [AudioPlayer] is stopped.
  get position => _position;

  _setPosition(Duration position) {
    _position = position;

    for (Function callback in _onPlayerPositionChangeds) {
      callback(position);
    }
  }

  void addListener({
    Function(AudioPlayerState) onStateChanged,
    Function onAudioLoading,
    Function(int) onBufferingUpdate,
    Function onAudioReady,
    Function(Duration) onAudioLengthChanged,
    Function onPlayerPlaying,
    Function(Duration) onPlayerPlaybackUpdate,
    Function onPlayerPaused,
    Function onPlayerStopped,
    Function onPlayerCompleted,
    Function onSeekStarted,
    Function onSeekCompleted,
  }) {
    if (onStateChanged != null) {
      _onStateChangeds.add(onStateChanged);
    }
    if (onAudioLoading != null) {
      _onAudioLoadings.add(onAudioLoading);
    }
    if (onBufferingUpdate != null) {
      _onBufferingUpdates.add(onBufferingUpdate);
    }
    if (onAudioReady != null) {
      _onAudioReadys.add(onAudioReady);
    }
    if (onAudioLengthChanged != null) {
      _onAudioLengthChangeds.add(onAudioLengthChanged);
    }
    if (onPlayerPlaying != null) {
      _onPlayerPlayings.add(onPlayerPlaying);
    }
    if (onPlayerPlaybackUpdate != null) {
      _onPlayerPositionChangeds.add(onPlayerPlaybackUpdate);
    }
    if (onPlayerPaused != null) {
      _onPlayerPauseds.add(onPlayerPaused);
    }
    if (onPlayerStopped != null) {
      _onPlayerStoppeds.add(onPlayerStopped);
    }
    if (onPlayerCompleted != null) {
      _onPlayerCompleteds.add(onPlayerCompleted);
    }
    if (onSeekStarted != null) {
      _onSeekStarteds.add(onSeekStarted);
    }
    if (onSeekCompleted != null) {
      _onSeekCompleteds.add(onSeekCompleted);
    }
  }

  void removeListener({
    Function(AudioPlayerState) onStateChanged,
    Function onAudioLoading,
    Function(int) onBufferingUpdate,
    Function onAudioReady,
    Function(Duration) onAudioLengthChanged,
    Function onPlayerPlaying,
    Function(Duration) onPlayerPlaybackUpdate,
    Function onPlayerPaused,
    Function onPlayerStopped,
    Function onPlayerCompleted,
    Function onSeekStarted,
    Function onSeekCompleted,
  }) {
    _onStateChangeds.remove(onStateChanged);
    _onAudioLoadings.remove(onAudioLoading);
    _onBufferingUpdates.remove(onBufferingUpdate);
    _onAudioReadys.remove(onAudioReady);
    _onAudioLengthChangeds.remove(onAudioLengthChanged);
    _onPlayerPlayings.remove(onPlayerPlaying);
    _onPlayerPositionChangeds.remove(onPlayerPlaybackUpdate);
    _onPlayerPauseds.remove(onPlayerPaused);
    _onPlayerStoppeds.remove(onPlayerStopped);
    _onPlayerCompleteds.remove(onPlayerCompleted);
    _onSeekStarteds.remove(onSeekStarted);
    _onSeekCompleteds.remove(onSeekCompleted);
  }

  void loadMedia(Uri uri) {
    _log.fine('loadMedia()');
    // TODO: how to represent media
    channel.invokeMethod(
      'audioplayer/$playerId/load',
      {
        'audioUrl': uri.toString()
      },
    );
  }

  void play() {
    _log.fine('play()');
    channel.invokeMethod('audioplayer/$playerId/play');
  }

  void pause() {
    _log.fine('pause()');
    channel.invokeMethod('audioplayer/$playerId/pause');
  }

  void seek(Duration duration) {
    _log.fine('seek(): $duration');
    channel.invokeMethod(
        'audioplayer/$playerId/seek',
        {
          'seekPosition': duration.inMilliseconds,
        },
    );
  }

  void stop() {
    _log.fine('stop()');
    channel.invokeMethod('audioplayer/$playerId/stop');
  }
}

enum AudioPlayerState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  completed,
}