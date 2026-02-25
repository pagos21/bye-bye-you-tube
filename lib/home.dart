import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:u_down2/better_player.dart';
import 'package:u_down2/player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ignore: library_prefixes
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as YT;

class Principale extends StatefulWidget {
  const Principale({super.key});

  @override
  State<Principale> createState() => _PrincipaleState();
}

class _PrincipaleState extends State<Principale> {
  bool isOnlyMp3 = false;
  String _userInput = "";
  String _statusText = "Esegui una ricerca";
  int _status = 0;
  List<Video> _searchRes = [];

  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  // final ValueNotifier<String> _statusNotifier = ValueNotifier<String>("Inizializzazione...");
  // 0 idle
  // 1 loading
  // 2 data
  // 3 downloading
  // 9 completato

  final _linkController = TextEditingController();

  _downloaderino(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _progressNotifier,
            builder: (context, progress, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Stack(
                      alignment: AlignmentGeometry.center,
                      children: [
                        Positioned(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.lerp(Colors.redAccent, Colors.green, progress)!,
                              ),
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                        ),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color.lerp(Colors.redAccent, Colors.green[900], progress)!,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(_statusText, textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  _spinnerino() {
    log("spinnerino");
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          CircularProgressIndicator(color: Colors.green),
          Text(_statusText),
        ],
      ),
    );
  }

  // bool _blasphemyHandler(String url) {
  //   var res = false;
  //   // ignore: non_constant_identifier_names
  //   List<String> black_list = ['porn', 'pornhub', 'xvid', 'spank'];
  //   for (var element in black_list) {
  //     if (url.contains(element)) {
  //       res = true;
  //     }
  //   }
  //   return res;
  // }

  Future<void> _execute({required String url, required String type}) async {
    _progressNotifier.value = 0.0;
    setState(() {
      // _progress = 0.0;
      // _status = 1;
      _statusText = "Scarico manifest e content";
    });
    // 1. Gestione Permessi
    PermissionStatus statusPer = type == 'mp3'
        ? await Permission.audio.status
        : await Permission.videos.status;

    if (statusPer.isDenied) {
      statusPer = type == 'mp3'
          ? await Permission.audio.request()
          : await Permission.videos.request();
    }

    if (statusPer.isGranted) {
      log("Permesso concesso. Inizio procedura...");
      var yt = YoutubeExplode();

      try {
        if (!mounted) return;
        _downloaderino(context);
        // 2. Recupero ID e Video
        String? youtubeId = YT.YoutubePlayer.convertUrlToId(url);
        if (youtubeId == null) throw Exception("URL non valido");

        var video = await yt.videos.get(youtubeId);

        setState(() {
          // _status = 3;
          _statusText = "Analisi stream...";
        });

        // 3. Selezione del contenuto
        var manifest = await yt.videos.streamsClient.getManifest(youtubeId);
        dynamic content;
        if (type == "mp3") {
          // Invece di manifest.audioOnly, usiamo il video più leggero che contiene l'audio
          // Il formato '18' (360p) è perfetto: è piccolo e il download è garantito
          content = manifest.muxed.where((e) => e.videoQuality.toString().contains('360')).first;
          log("Uso il flusso muxed leggero per estrarre l'audio");
        } else {
          content = manifest.muxed.withHighestBitrate();
        }

        // 4. Preparazione File (Pulizia nome e percorso)
        // Puliamo il titolo da caratteri che Android non accetta nei nomi file
        String safeTitle = video.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), "_");
        if (safeTitle.length > 20) safeTitle = safeTitle.substring(0, 20);
        String extension = type == 'mp3' ? 'm4a' : 'mp4';

        // Assicurati che getFilePath usi questo safeTitle per comporre il path
        var pp = await getFilePath("$safeTitle.$extension");
        var file = File(pp);

        if (file.existsSync()) await file.delete();

        // 5. Download a blocchi (Stream)
        var stream = yt.videos.streamsClient.get(content);
        var fileStream = file.openWrite(mode: FileMode.writeOnlyAppend);

        int downloaded = 0;
        int totalSize = content.size.totalBytes;

        log("Inizio scrittura su: $pp");

        await for (var data in stream) {
          fileStream.add(data);
          downloaded += data.length;
          // Questo aggiorna automaticamente chiunque stia "ascoltando"
          _progressNotifier.value = downloaded / totalSize;
          // _statusNotifier.value = "Scaricando: ${((downloaded / totalSize) * 100).toInt()}%";

          // Aggiorniamo la UI ogni tanto per mostrare il progresso
          setState(() {
            // _progress = (downloaded / totalSize);
            // _statusText = "Scaricando: ${(_progress * 100).toStringAsFixed(1)}%";
            _statusText = "DOWNLOAD IN CORSO";
          });
        }

        // 6. Chiusura e pulizia
        await fileStream.flush();
        await fileStream.close();

        // Opzionale: Aspetta circa mezzo secondo per far vedere il 100% all'utente
        await Future.delayed(const Duration(milliseconds: 800));

        // CHIUDI LA DIALOG
        if (mounted) {
          // Verifica che l'app sia ancora visibile
          Navigator.pop(context);
        }

        setState(() {
          _status = 9;
          _statusText = pp;
        });
      } catch (e) {
        log("ERRORE CRITICO: $e");
        setState(() {
          _status = 0;
          _statusText = "Errore: $e";
        });
      } finally {
        yt.close();
      }
    } else {
      log("Permesso negato dall'utente");
    }
  }

  Future<String> getFilePath(String extension) async {
    String filename = extension;
    String filePath = "/storage/emulated/0/Music/";
    if (Directory(filePath).existsSync()) {
      return filePath + filename;
    } else {
      Directory? appDocumentssDir = await getApplicationDocumentsDirectory();
      log(appDocumentssDir.toString());
      return appDocumentssDir.toString() + filename;
    }
  }

  Future<void> _cerca(String query) async {
    log("eseguo ricerca");
    final yt = YoutubeExplode();
    if (query.isEmpty) return;
    //essegno stato di loading e pulisco la query precedente
    setState(() {
      _status = 1;
      _statusText = "cerco su YT... Stai calmo";
      _searchRes.clear();
    });
    try {
      VideoSearchList searchList = await yt.search.search(query);
      setState(() {
        _searchRes = searchList;
      });
    } catch (e) {
      log("Errore nella ricerca: $e");
    } finally {
      setState(() {
        _status = 0;
      });
    }
  }

  // convertitore della durata del vide
  String _videoDuration(Duration? duration) {
    if (duration == null) {
      return "--:--";
    }
    //lambda in flutter
    String duedigits(int n) => n.toString().padLeft(2, "0");
    // ad esempio se fosse la durata di 130 i remainder darebbe 10
    String min = duedigits(duration.inMinutes.remainder(60));
    String sec = duedigits(duration.inSeconds.remainder(60));
    // se è un video di ore
    if (duration.inHours > 0) {
      return "${duedigits(duration.inHours)}:$min:$sec";
    }
    return "$min:$sec";
  }

  Widget _risultatiBuilder() {
    return Expanded(
      child: _status == 1
          ? _spinnerino()
          : ListView.builder(
              itemCount: _searchRes.length,
              itemBuilder: (context, index) {
                final video = _searchRes[index];
                return Card(
                  elevation: 6,
                  shadowColor: Colors.teal,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        InkWell(
                          splashColor: Colors.green,
                          onTap: () => LoadingOverlay.of(context).show(
                            video: video,
                            isOnlyAudio: false,
                            download: (url, type) => _execute(url: url, type: type),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(10),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    video.thumbnails.highResUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 5,
                                child: Container(
                                  color: Colors.black54,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(
                                      _videoDuration(video.duration),
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(video.author),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => LoadingOverlay.of(context).show(
                                video: video,
                                isOnlyAudio: true,
                                download: (url, type) => _execute(url: url, type: type),
                              ),
                              child: Icon(Icons.audiotrack),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).push(MaterialPageRoute(builder: (context) => NeonTestPlayer()));
                              },
                              // onPressed: () => LoadingOverlay.of(context).show(
                              //   video: video,
                              //   isOnlyAudio: false,
                              //   download: (url, type) => _execute(url: url, type: type),
                              // ),
                              child: Icon(Icons.videocam),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final double _width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        // ignore: prefer_const_constructors
        title: const Text("Yotube Mp3 Downloader and Beyond"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _linkController,
              onSubmitted: (_userInput == "")
                  ? null
                  : (val) {
                      FocusScope.of(context).unfocus();
                      _cerca(val);
                    },
              decoration: const InputDecoration(labelText: "Cerca su YT"),
              onChanged: (value) {
                setState(() {
                  _userInput = value;
                });
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ElevatedButton(
                onPressed: (_userInput == "")
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        _cerca(_linkController.value.text);
                      },
                child: const Text("Cerca"),
              ),
            ),
            const SizedBox(height: 30),

            _risultatiBuilder(),
            const SizedBox(),
          ],
        ),
      ),
    );
  }
}
