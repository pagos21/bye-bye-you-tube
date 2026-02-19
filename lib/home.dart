import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ignore: library_prefixes
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as YT;

class Principale extends StatefulWidget {
  const Principale({super.key});

  @override
  State<Principale> createState() => _PrincipaleState();
}

class _PrincipaleState extends State<Principale> {
  //var here

  bool isOnlyMp3 = false;
  String _userInput = "";
  dynamic _thumbnail = "";
  String _title = "";
  String _descr = "";
  String _statusText = "Esegui una ricerca";
  int _status = 0;
  // double _progress = 0.0;
  bool _alreadyPlayed = false;

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

  bool _blasphemyHandler(String url) {
    var res = false;
    // ignore: non_constant_identifier_names
    List<String> black_list = ['porn', 'pornhub', 'xvid', 'spank'];
    for (var element in black_list) {
      if (url.contains(element)) {
        res = true;
      }
    }
    return res;
  }

  Future<void> searchThumbnail(String url) async {
    log("searching");
    bool isBlasphemy = _blasphemyHandler(url);
    if (isBlasphemy) {
      setState(() {
        _status = 2;
        _thumbnail = SizedBox(
          width: double.infinity,
          child: Image.asset("assets/images/sb_ho.jpg", fit: BoxFit.fill),
        );
        _title = "boo";
        _descr = "humm...";
      });
      return;
    }
    try {
      setState(() {
        _statusText = "Cerco...";
        _status = 1;
      });
      final yt = YoutubeExplode();
      final video = await yt.videos.get(url);
      setState(() {
        _status = 2;
        _thumbnail = Image.network(video.thumbnails.highResUrl);
        _title = video.title;
        _descr = video.description;
      });
    } catch (e) {
      setState(() {
        _status = -1;
        _statusText = "url non valido";
      });
    }
  }

  Future<void> execute(String url, String type) async {
    _progressNotifier.value = 0.0;
    setState(() {
      // _progress = 0.0;
      // _status = 1;
      _statusText = "Scarico manifest e content";
      _alreadyPlayed = false;
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
    String filePath = "/storage/emulated/0/Download/";
    if (Directory(filePath).existsSync()) {
      return filePath + filename;
    } else {
      Directory? appDocumentssDir = await getApplicationDocumentsDirectory();
      log(appDocumentssDir.toString());
      return appDocumentssDir.toString() + filename;
    }
  }

  Widget _content() {
    if (_status == 1) {
      return _spinnerino();
    }
    if (_status == 2) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: _thumbnail,
                ),
                Positioned(
                  bottom: 10,
                  left: 5,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(7),
                    child: SizedBox(
                      width: 250,
                      child: Text(
                        overflow: TextOverflow.fade,
                        _title,
                        style: const TextStyle(color: Colors.white),
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(_descr, style: TextStyle(color: Colors.grey[600])),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => execute(_userInput, "mp3"),
                    child: const Icon(Icons.audiotrack_rounded),
                  ),
                  ElevatedButton(
                    onPressed: () => execute(_userInput, "mp4"),
                    child: const Icon(Icons.videocam),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_status == -1) {
      return const Text("Copertina inesistente o URL non valido");
    }
    //  else if (_status == 3) {
    //   _spinnerino();
    // }
    else if (_status == 9) {
      if (!_alreadyPlayed) {
        OpenFile.open(_statusText);
        _alreadyPlayed = true;
      }
      return TextButton(
        onPressed: () {
          OpenFile.open(_statusText);
        },
        child: Text(_statusText),
      );
    }
    return SizedBox();
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _linkController,
                onTap: () => _linkController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _linkController.value.text.length,
                ),
                decoration: const InputDecoration(labelText: "Yotube link"),
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
                          searchThumbnail(_userInput);
                        },
                  child: const Text("Cerca"),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _content()),
              ),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
