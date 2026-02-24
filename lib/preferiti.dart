import 'package:flutter/material.dart';
import 'package:u_down2/collections/preferito_collection.dart';
import 'package:u_down2/db/db_service.dart';
import 'package:u_down2/player.dart';

class Preferiti extends StatelessWidget {
  const Preferiti({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Preferiti"), centerTitle: true),
      body: StreamBuilder<List<PreferitoCollection>>(
        stream: mydbService.watchPreferiti(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox();

          final favs = snapshot.data!;
          if (favs.isEmpty) {
            return Center(child: Text("Non hai ancora inserito nessun preferito"));
          }
          return ListView.builder(
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final fav = favs[index];
              return ListTile(
                onTap: () => LoadingOverlay.of(
                  context,
                ).show(video: fav.toVideo(), download: (url, type) {}, isOnlyAudio: false),
                leading: Image.network(fav.thumbnailUrl),
                title: Text(fav.title),
                subtitle: Text(fav.author),
                trailing: IconButton(
                  onPressed: () => mydbService.togglePreferito(fav),
                  icon: Icon(Icons.bookmark_remove),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
