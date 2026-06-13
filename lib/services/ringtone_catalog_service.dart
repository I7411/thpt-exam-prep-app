class RingtoneItem {
  final String name;
  final String assetPath;
  final String androidRawName;

  const RingtoneItem({
    required this.name,
    required this.assetPath,
    required this.androidRawName,
  });
}

class RingtoneCatalogService {
  static const List<RingtoneItem> ringtones = [
    RingtoneItem(
      name: 'Mạnh mẽ (Piano Cover)',
      assetPath: 'assets/audios/file.mp3',
      androidRawName: 'file',
    ),
    RingtoneItem(
      name: 'Nhẹ nhàng (Gentle Tone)',
      assetPath: 'assets/audios/alarm_gentle.wav',
      androidRawName: 'alarm_gentle',
    ),
  ];

  static RingtoneItem getByAssetPath(String assetPath) {
    return ringtones.firstWhere(
      (r) => r.assetPath == assetPath,
      orElse: () => ringtones.first,
    );
  }
}
