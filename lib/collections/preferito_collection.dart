import 'package:isar_community/isar.dart';

part 'preferito_collection.g.dart';

@collection
class PreferitoCollection {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true, type: IndexType.value)
  late String youtubeId;
  //per la ricerca testuale
  @Index(type: IndexType.value)
  late String title;
  late String author;
  late String thumbnailUrl;
  //per i tag (da fare magari in futuro)
  @Index(type: IndexType.value)
  List<String> tags = [];
  @Index()
  DateTime addedAt = DateTime.now();
}
