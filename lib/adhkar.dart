import 'package:flutter/material.dart';

const _kursi =
    'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ ۗ مَن ذَا ٱلَّذِى يَشْفَعُ عِندَهُۥٓ إِلَّا بِإِذْنِهِۦ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَىْءٍ مِّنْ عِلْمِهِۦٓ إِلَّا بِمَا شَآءَ ۚ وَسِعَ كُرْسِيُّهُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضَ ۖ وَلَا يَـُٔودُهُۥ حِفْظُهُمَا ۚ وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ';

List<List<Object>> _daily(bool m) => [
      ['${m ? 'أصبحنا وأصبح' : 'أمسينا وأمسى'} الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير', 1],
      [_kursi, 1],
      ['قراءة سور الإخلاص والفلق والناس', 3],
      [m ? 'اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور' : 'اللهم بك أمسينا، وبك أصبحنا، وبك نحيا، وبك نموت، وإليك المصير', 1],
      ['بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم', 3],
      ['رضيت بالله ربًا، وبالإسلام دينًا، وبمحمد ﷺ نبيًا', 3],
      ['حسبي الله لا إله إلا هو، عليه توكلت وهو رب العرش العظيم', 7],
      ['اللهم إني أسألك العفو والعافية في الدنيا والآخرة', 1],
      ['أعوذ بكلمات الله التامات من شر ما خلق', 3],
      ['سبحان الله وبحمده', 100],
      ['أستغفر الله وأتوب إليه', 100],
    ];

final Map<String, List<List<Object>>> _data = {
  'الصباح': _daily(true),
  'المساء': _daily(false),
  'النوم': [
    [_kursi, 1],
    ['قراءة سور الإخلاص والفلق والناس ثم المسح على الجسد', 3],
    ['باسمك اللهم أموت وأحيا', 1],
    ['اللهم قني عذابك يوم تبعث عبادك', 3],
    ['سبحان الله', 33],
    ['الحمد لله', 33],
    ['الله أكبر', 34],
  ],
  'بعد الصلاة': [
    ['أستغفر الله', 3],
    ['اللهم أنت السلام ومنك السلام، تباركت يا ذا الجلال والإكرام', 1],
    ['سبحان الله', 33],
    ['الحمد لله', 33],
    ['الله أكبر', 33],
    ['لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير', 1],
  ],
  'عامة': [
    ['لا حول ولا قوة إلا بالله', 33],
    ['لا إله إلا أنت سبحانك إني كنت من الظالمين', 3],
    ['ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار', 1],
    ['اللهم صل وسلم على نبينا محمد', 10],
  ],
};

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});
  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  String cat = 'الصباح';
  final left = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final list = _data[cat]!;
    return Column(children: [
      SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          children: _data.keys
              .map((k) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                        label: Text(k),
                        selected: k == cat,
                        onSelected: (_) => setState(() => cat = k)),
                  ))
              .toList(),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (c, i) {
            final key = '$cat$i';
            final r = left[key] ?? list[i][1] as int;
            return Card(
              child: InkWell(
                onTap: () => setState(() {
                  if (r > 0) left[key] = r - 1;
                }),
                onLongPress: () => setState(() => left.remove(key)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(
                        child: Text(list[i][0] as String,
                            style: const TextStyle(fontSize: 18, height: 1.9))),
                    const SizedBox(width: 12),
                    CircleAvatar(
                        radius: 24,
                        backgroundColor: r == 0 ? Colors.green : null,
                        child: r == 0
                            ? const Icon(Icons.check, color: Colors.white)
                            : Text('$r')),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
