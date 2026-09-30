import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/storage.dart';
import '../data/adhkar_data.dart';

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  String selectedCategory = 'الصباح';
  final Map<String, int> progress = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final list = adhkarData[selectedCategory] ?? [];
    for (int i = 0; i < list.length; i++) {
      final remaining = AppStorage.getAdhkarProgress(
        selectedCategory,
        i,
      );
      final count = list[i][1] as int;
      progress['$selectedCategory$i'] = remaining > 0 ? remaining : count;
    }
    setState(() {});
  }

  Future<void> _decrementAdhkar(int index) async {
    final key = '$selectedCategory$index';
    final current = progress[key] ?? 1;
    if (current > 0) {
      final newValue = current - 1;
      progress[key] = newValue;
      await AppStorage.saveAdhkarProgress(
        selectedCategory,
        index,
        newValue,
      );
      setState(() {});
    }
  }

  Future<void> _resetCategory() async {
    final list = adhkarData[selectedCategory] ?? [];
    for (int i = 0; i < list.length; i++) {
      progress['$selectedCategory$i'] = list[i][1] as int;
      await AppStorage.saveAdhkarProgress(
        selectedCategory,
        i,
        list[i][1] as int,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = adhkarData[selectedCategory] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // الفئات
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            children: adhkarData.keys.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                      _loadProgress();
                    });
                  },
                  selectedColor: kGreen,
                  labelStyle: TextStyle(
                    color: selectedCategory == category
                        ? Colors.white
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // الأذكار
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final adhkar = list[index];
              final text = adhkar[0] as String;
              final count = adhkar[1] as int;
              final key = '$selectedCategory$index';
              final remaining = progress[key] ?? count;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: remaining > 0
                      ? () => _decrementAdhkar(index)
                      : null,
                  onLongPress: () => _resetCategory(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            text,
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              height: 1.9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: remaining == 0
                              ? kGreen
                              : kGold.withValues(alpha: 0.2),
                          child: remaining == 0
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
                                  '$remaining',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kGold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
