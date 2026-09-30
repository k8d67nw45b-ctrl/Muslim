class AdhkarItem {
  final String text;
  final int count;
  final String category;
  final int index;

  const AdhkarItem({
    required this.text,
    required this.count,
    required this.category,
    required this.index,
  });

  String get id => '${category}_$index';

  bool isComplete(int remaining) => remaining == 0;
}

class AdhkarCategory {
  static const String morning = 'الصباح';
  static const String evening = 'المساء';
  static const String sleep = 'النوم';
  static const String afterPrayer = 'بعد الصلاة';
  static const String general = 'عامة';
  static const String hisn = 'حصن المسلم';

  static const List<String> all = [
    morning,
    evening,
    sleep,
    afterPrayer,
    general,
    hisn,
  ];
}
