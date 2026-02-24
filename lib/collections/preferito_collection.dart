import 'package:isar_community/isar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

  Video toVideo() {
    return Video(
      VideoId(youtubeId),
      title,
      author,
      ChannelId("UChiRQu1TjN13c4NfFKOcpFQ"),
      null,
      null,
      null,
      "",
      Duration.zero,
      ThumbnailSet(thumbnailUrl),
      null,
      Engagement(0, null, null),
      false,
    );
  }
}
