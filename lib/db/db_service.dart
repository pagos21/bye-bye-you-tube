import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:u_down2/collections/preferito_collection.dart';

class DbService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([PreferitoCollectionSchema], directory: dir.path);
  }

  // logica di salvataggio (con toggle)
  Future<void> togglePreferito(PreferitoCollection video) async {
    await isar.writeTxn(() async {
      final exist = await isar.preferitoCollections
          .filter()
          .youtubeIdEqualTo(video.youtubeId)
          .findFirst();
      if (exist != null) {
        //il video esiste già quindo lo elimino (ricorda che siamo in modalità toggle)
        await isar.preferitoCollections.delete(exist.id);
      } else {
        // ok il video non esiste lo inserisco
        await isar.preferitoCollections.put(video);
      }
    });
  }

  // logica di lettura (in modalità STREAM) real time
  Stream<List<PreferitoCollection>> watchPreferiti() {
    return isar.preferitoCollections.where().watch(fireImmediately: true);
  }

  Future<PreferitoCollection?> getVideo(String id) async {
    return await isar.preferitoCollections.filter().youtubeIdEqualTo(id).findFirst();
  }
}

//creo instalza globale
final mydbService = DbService();
