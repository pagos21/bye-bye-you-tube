import 'dart:developer';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// class NeonTestPlayer extends StatefulWidget {
//   const NeonTestPlayer({super.key});

//   @override
//   State<NeonTestPlayer> createState() => _NeonTestPlayerState();
// }

// class _NeonTestPlayerState extends State<NeonTestPlayer> {
//   BetterPlayerController? _betterPlayerController;
//   final String _testVideoId = "jGCU7AmOYhU"; // L'ID del video di test

//   @override
//   void initState() {
//     super.initState();
//     _initNeonPlayer();
//   }

//   // Sostituisce _setupPlayer: ora usa la logica intelligente di createDataSource
//   void _initNeonPlayer() async {
//     try {
//       // 1. Otteniamo il DataSource pre-configurato (HLS o Muxed)
//       final dataSource = await createDataSource(_testVideoId);

//       // 2. Inizializziamo il controller con le impostazioni grafiche Neon
//       setState(() {
//         _betterPlayerController = BetterPlayerController(
//           const BetterPlayerConfiguration(
//             allowedScreenSleep: false,
//             fullScreenByDefault: false,
//             autoPlay: true,
//             aspectRatio: 16 / 9,
//             handleLifecycle: false, // Gestisce pausa/play quando esci dall'app
//           ),
//           betterPlayerDataSource: dataSource,
//         );
//       });
//     } catch (e) {
//       log("Errore durante l'inizializzazione del player: $e");
//     }
//   }

//   // La tua funzione migliorata: ora gestisce anche la chiusura del client YT
//   Future<BetterPlayerDataSource> createDataSource(String videoId) async {
//     final yt = YoutubeExplode();

//     try {
//       // Otteniamo sia il video (per il titolo) che il manifesto degli stream
//       final video = await yt.videos.get(videoId);
//       final manifest = await yt.videos.streamsClient.getManifest(videoId);

//       final Map<String, String> headers = {
//         "User-Agent": "Mozilla/5.0 (Android 12; Mobile; rv:94.0) Gecko/94.0 Firefox/94.0",
//         "Referer": "https://www.youtube.com/",
//       };

//       // Notifica personalizzata con i dati reali del video
//       final notificationConfig = BetterPlayerNotificationConfiguration(
//         showNotification: true,
//         title: "video.title",
//         author: "video.author",
//         imageUrl: video.thumbnails.highResUrl,
//       );

//       // PRIORITÀ 1: HLS
//       if (manifest.hls.isNotEmpty) {
//         log("Utilizzando stream HLS per: $videoId");
//         return BetterPlayerDataSource(
//           BetterPlayerDataSourceType.network,
//           manifest.hls.first.url.toString(),
//           videoFormat: BetterPlayerVideoFormat.hls,
//           headers: headers,
//           notificationConfiguration: notificationConfig,
//         );
//       }

//       // PRIORITÀ 2: MUXED (Salvagente)
//       log("HLS non trovato, utilizzo stream MUXED per: $videoId");
//       final muxedStream = manifest.muxed.withHighestBitrate();
//       return BetterPlayerDataSource(
//         BetterPlayerDataSourceType.network,
//         muxedStream.url.toString(),
//         videoFormat: BetterPlayerVideoFormat.other,
//         headers: headers,
//         notificationConfiguration: notificationConfig,

//         bufferingConfiguration: const BetterPlayerBufferingConfiguration(
//           minBufferMs: 5000,
//           maxBufferMs: 30000,
//           bufferForPlaybackMs: 2500,
//           bufferForPlaybackAfterRebufferMs: 5000,
//         ),
//       );
//     } finally {
//       yt.close(); // Chiudiamo sempre il client per liberare risorse
//     }
//   }

//   @override
//   void dispose() {
//     _betterPlayerController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text("Neon Player Pro", style: TextStyle(color: Colors.cyanAccent)),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.cyanAccent),
//       ),
//       body: Center(
//         child: _betterPlayerController == null
//             ? const CircularProgressIndicator(color: Colors.cyan)
//             : BetterPlayer(controller: _betterPlayerController!),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class NeonTestPlayer extends StatefulWidget {
  const NeonTestPlayer({super.key});

  @override
  State<NeonTestPlayer> createState() => _NeonTestPlayerState();
}

class _NeonTestPlayerState extends State<NeonTestPlayer> {
  late final _controller;
  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(),
      betterPlayerDataSource: dataSource,
    );
  }
  // final dataSource = BetterPlayerDataSource(
  //   BetterPlayerDataSourceType.network,
  //   'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  // );

  BetterPlayerDataSource dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    notificationConfiguration: BetterPlayerNotificationConfiguration(
      showNotification: true,
      title: "Elephant dream",
      author: "Some author",
      imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/African_Bush_Elephant.jpg/1200px-African_Bush_Elephant.jpg",
      activityName: "MainActivity",
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Center(child: BetterPlayer(controller: _controller));
  }
}
