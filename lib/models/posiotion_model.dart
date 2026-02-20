import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class PositionData {
  final Duration position;
  final Duration bufferPosition;
  final Duration duration;
  PositionData(this.position, this.bufferPosition, this.duration);
}

Stream<PositionData> positionDataStream(AudioPlayer audioPlayer) =>
    Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      audioPlayer.positionStream,
      audioPlayer.bufferedPositionStream,
      audioPlayer.durationStream,
      (pos, buffPos, dur) => PositionData(pos, buffPos, dur ?? Duration.zero),
    );
