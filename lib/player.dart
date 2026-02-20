import 'dart:developer';
import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:u_down2/models/posiotion_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class LoadingOverlay {
  BuildContext _context;

  void hide() {
    Navigator.of(_context).pop();
  }

  void show({
    required Video video,
    required Function(String url, String type) download,
  }) {
    showGeneralDialog(
      context: _context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryanim) =>
          _FullScreenLoader(video: video, download: download),
    );
  }

  LoadingOverlay._create(this._context);

  factory LoadingOverlay.of(BuildContext context) {
    return LoadingOverlay._create(context);
  }
}

class _FullScreenLoader extends StatefulWidget {
  final Video video;
  final Function download;

  const _FullScreenLoader({required this.video, required this.download});
  @override
  State<_FullScreenLoader> createState() => __FullScreenLoaderState();
}

class __FullScreenLoaderState extends State<_FullScreenLoader> {
  final yt = YoutubeExplode();
  late Video _video;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPaused = false;
  RelatedVideosList? _relatedVideos;
  int _currentIndex = 0;
  bool _loopPlay = false;

  @override
  void initState() {
    _video = widget.video;
    _playAudio(_video);
    //listener per passare al video/musica succesiva al termine
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && !_loopPlay) {
        _playNext();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    yt.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(Video newVideo) async {
    try {
      final yt = YoutubeExplode();
      if (_relatedVideos == null) {
        final rel = await yt.videos.getRelatedVideos(_video);
        setState(() {
          _relatedVideos = rel;
        });
        for (var item in _relatedVideos!) {
          log(item.title);
        }
      }
      if (_currentIndex + 1 == _relatedVideos!.length) {
        _newReletedVideos();
      }
      final StreamManifest manifest = await yt.videos.streamsClient.getManifest(
        newVideo.url,
      );
      final AudioStreamInfo audioInfo = manifest.muxed
          .withHighestBitrate(); // usare sempre muxed anche per audio e cazzo ignora audioOnly che non va
      String finalUrl = audioInfo.url.toString();
      if (!finalUrl.contains("ratebypass=yes")) {
        finalUrl += "&ratebypass=yes";
      }
      await _audioPlayer.setUrl(finalUrl);
      final source = AudioSource.uri(
        audioInfo.url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        },
      );

      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(source, preload: false);
      _audioPlayer.play();
      yt.close();
      setState(() {
        _video = newVideo;
      });
    } catch (e) {
      log("errore: $e");
    }
  }

  _pauseAudioToggle() {
    _isPaused ? _audioPlayer.play() : _audioPlayer.pause();
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  _playNext() {
    _currentIndex++;
    final nextVideo = _relatedVideos?[_currentIndex];
    if (nextVideo == null) return;
    setState(() {
      _video = nextVideo;
    });
    _playAudio(nextVideo);
  }

  _newReletedVideos() async {
    final lastVideo = _relatedVideos!.last;
    final newRel = await yt.videos.getRelatedVideos(lastVideo);
    setState(() {
      _relatedVideos = newRel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: mq.size.width,
        height: mq.size.height,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Align(
            alignment: AlignmentGeometry.bottomCenter,
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: const Color.fromARGB(50, 1, 63, 53),
              ),
              child: Column(
                children: [
                  SizedBox(height: mq.padding.top),
                  Image.network(
                    _video.thumbnails.highResUrl,
                    fit: BoxFit.cover,
                    height: 300,
                    width: mq.size.width,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,

                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(0),
                      shrinkWrap: true,
                      itemCount: _relatedVideos?.length ?? 0,
                      itemBuilder: (context, index) {
                        if (_relatedVideos == null) {
                          return SizedBox();
                        }
                        final Video reletedVideo = _relatedVideos![index];
                        return ListTile(
                          leading: Image.network(
                            reletedVideo.thumbnails.highResUrl,
                          ),
                          title: Text(
                            reletedVideo.title,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            reletedVideo.author,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            _playAudio(reletedVideo);
                            _newReletedVideos();
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                      left: 15.0,
                      right: 15,
                      bottom: 10,
                      top: 23,
                    ),
                    // width: mq.size.width,
                    child: StreamBuilder<PositionData>(
                      stream: positionDataStream(_audioPlayer),
                      builder: (context, snapshot) {
                        final posData = snapshot.data;
                        return ProgressBar(
                          progress: posData?.position ?? Duration.zero,
                          total: posData?.duration ?? Duration.zero,
                          buffered: posData?.bufferPosition ?? Duration.zero,
                          progressBarColor: Colors.teal,
                          baseBarColor: Colors.white.withValues(alpha: 0.24),
                          bufferedBarColor: Colors.white.withValues(
                            alpha: 0.24,
                          ),

                          thumbColor: Colors.teal[200],
                          timeLabelPadding: 5,
                          timeLabelTextStyle: TextStyle(
                            color: Colors.teal[100],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          barHeight: 5,
                          thumbRadius: 7,
                          onSeek: (value) {
                            _audioPlayer.seek(value);
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    color: Color.fromARGB(150, 0, 0, 0),
                    height: 100,
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          splashColor: Colors.tealAccent,
                          onTap: () {
                            setState(() {
                              _loopPlay = !_loopPlay;
                              if (_loopPlay) {
                                _audioPlayer.setLoopMode(LoopMode.one);
                              } else {
                                _audioPlayer.setLoopMode(LoopMode.off);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              // border: Border.all(
                              //   color: _loopPlay
                              //       ? Colors.tealAccent[200]!
                              //       : Colors.transparent,
                              //   width: 1.5,
                              // ),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  color: _loopPlay
                                      ? Colors.teal[700]!.withValues(alpha: 0.6)
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.repeat,
                              color: _loopPlay
                                  ? Colors.teal[200]
                                  : Colors.teal[300],
                              size: _loopPlay ? 40 : 30,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Icon(
                            Icons.skip_previous,
                            color: Colors.teal[300],
                            size: 50,
                          ),
                        ),
                        GestureDetector(
                          onTap: _pauseAudioToggle,
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.teal[300],
                            size: 50,
                          ),
                        ),
                        Icon(
                          Icons.skip_next,
                          color: Colors.teal[300],
                          size: 50,
                        ),
                        InkWell(
                          splashColor: Colors.teal,
                          onTap: () {
                            log("tap");
                            widget.download(_video.url, 'mp3');
                          },
                          child: Icon(
                            Icons.download,
                            color: Colors.teal[300],
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
