import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

const kGreen = Color(0xFF0B6E4F);
const kDeep = Color(0xFF06382A);
const kGold = Color(0xFFC9A227);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: kGreen,
    brightness: brightness,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor:
        dark ? const Color(0xFF0C1512) : const Color(0xFFF3F6F2),

    textTheme: GoogleFonts.cairoTextTheme(base.textTheme),

    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: dark ? Colors.white : kDeep,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          dark ? const Color(0xFF111C18) : Colors.white,
      indicatorColor: kGold.withValues(alpha: .28),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Store.init();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'رفيق المسلم',

      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,

      builder: (context, child) {
        return Title(
          title: 'رفيق المسلم',
          color: kGreen,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      home: const Home(),
    );
  }
}

class Msg extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const Msg(
    this.text, {
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Colors.grey.shade500,
            ),

            const SizedBox(height: 12),

            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 14),

              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StarBadge extends StatelessWidget {
  final String label;
  final double size;

  const StarBadge(
    this.label, {
    super.key,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    Widget square(double angle) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: size * .72,
          height: size * .72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            border: Border.all(
              color: color.withValues(alpha: .5),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          square(0),
          square(pi / 4),

          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// التخزين المحلي
// ============================================================

class Store {
  static late SharedPreferences p;

  static Future<void> init() async {
    p = await SharedPreferences.getInstance();
  }

  // آخر صفحة في القرآن
  static int get lastPage {
    return p.getInt('last_page') ?? 1;
  }

  static set lastPage(int value) {
    p.setInt('last_page', value);
  }

  // العلامات المرجعية
  static List<int> get marks {
    return (p.getStringList('marks') ?? [])
        .map(int.parse)
        .toList();
  }

  static void toggleMark(int page) {
    final list = marks;

    if (list.contains(page)) {
      list.remove(page);
    } else {
      list.add(page);
    }

    list.sort();

    p.setStringList(
      'marks',
      list.map((e) => e.toString()).toList(),
    );
  }

  static void clearMarks() {
    p.remove('marks');
  }

  // إعدادات التطبيق
  static bool get prayerNotifications {
    return p.getBool('prayer_notifications') ?? false;
  }

  static set prayerNotifications(bool value) {
    p.setBool('prayer_notifications', value);
  }

  static bool get saveLastPage {
    return p.getBool('save_last_page') ?? true;
  }

  static set saveLastPage(bool value) {
    p.setBool('save_last_page', value);
  }

  // تقدم الحج والعمرة
  static bool getHajjStep(String key) {
    return p.getBool('hajj_$key') ?? false;
  }

  static Future<void> setHajjStep(
    String key,
    bool value,
  ) async {
    await p.setBool('hajj_$key', value);
  }
}

// ============================================================
// أدوات مساعدة
// ============================================================

class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const AppSectionCard({
    super.key,
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: .5),
        ),
      ),
      child: child,
    );
  }
}
// ===============================
// القسم الثاني: القرآن الكريم
// ===============================

const List<String> rmSurahNames = [
  'الفاتحة',
  'البقرة',
  'آل عمران',
  'النساء',
  'المائدة',
  'الأنعام',
  'الأعراف',
  'الأنفال',
  'التوبة',
  'يونس',
  'هود',
  'يوسف',
  'الرعد',
  'إبراهيم',
  'الحجر',
  'النحل',
  'الإسراء',
  'الكهف',
  'مريم',
  'طه',
  'الأنبياء',
  'الحج',
  'المؤمنون',
  'النور',
  'الفرقان',
  'الشعراء',
  'النمل',
  'القصص',
  'العنكبوت',
  'الروم',
  'لقمان',
  'السجدة',
  'الأحزاب',
  'سبأ',
  'فاطر',
  'يس',
  'الصافات',
  'ص',
  'الزمر',
  'غافر',
  'فصلت',
  'الشورى',
  'الزخرف',
  'الدخان',
  'الجاثية',
  'الأحقاف',
  'محمد',
  'الفتح',
  'الحجرات',
  'ق',
  'الذاريات',
  'الطور',
  'النجم',
  'القمر',
  'الرحمن',
  'الواقعة',
  'الحديد',
  'المجادلة',
  'الحشر',
  'الممتحنة',
  'الصف',
  'الجمعة',
  'المنافقون',
  'التغابن',
  'الطلاق',
  'التحريم',
  'الملك',
  'القلم',
  'الحاقة',
  'المعارج',
  'نوح',
  'الجن',
  'المزمل',
  'المدثر',
  'القيامة',
  'الإنسان',
  'المرسلات',
  'النبأ',
  'النازعات',
  'عبس',
  'التكوير',
  'الانفطار',
  'المطففين',
  'الانشقاق',
  'البروج',
  'الطارق',
  'الأعلى',
  'الغاشية',
  'الفجر',
  'البلد',
  'الشمس',
  'الليل',
  'الضحى',
  'الشرح',
  'التين',
  'العلق',
  'القدر',
  'البينة',
  'الزلزلة',
  'العاديات',
  'القارعة',
  'التكاثر',
  'العصر',
  'الهمزة',
  'الفيل',
  'قريش',
  'الماعون',
  'الكوثر',
  'الكافرون',
  'النصر',
  'المسد',
  'الإخلاص',
  'الفلق',
  'الناس',
];

const List<int> rmSurahPages = [
  1, 2, 50, 77, 106, 128, 151, 177, 187, 208,
  221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
  322, 332, 342, 350, 359, 367, 377, 385, 396, 404,
  411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
  477, 483, 489, 496, 499, 502, 507, 511, 515, 518,
  520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
  551, 553, 554, 556, 558, 560, 562, 564, 566, 568,
  570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
  586, 587, 587, 589, 590, 591, 591, 592, 593, 594,
  595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
  600, 600, 601, 601, 601, 602, 602, 602, 603, 603,
  603, 604, 604, 604,
];

const List<int> rmJuzPages = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
  201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
  402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
];

String rmSurahOfPage(int page) {
  var index = 0;

  for (var i = 0; i < rmSurahPages.length; i++) {
    if (rmSurahPages[i] <= page) {
      index = i;
    }
  }

  return rmSurahNames[index];
}

int rmJuzOfPage(int page) {
  var index = 0;

  for (var i = 0; i < rmJuzPages.length; i++) {
    if (rmJuzPages[i] <= page) {
      index = i;
    }
  }

  return index + 1;
}

String rmPageUrl(int page, bool dark) {
  return 'https://cdn.jsdelivr.net/gh/'
      'SakinaDevGroup/mushaf-madani-cdn@main/'
      '${dark ? 'dark' : 'light'}/p$page.png';
}

final rmMushafCache = cache.CacheManager(
  cache.Config(
    'rafeeqMuslimMushaf',
    stalePeriod: const Duration(days: 3650),
    maxNrOfCacheObjects: 1500,
  ),
);

ImageProvider rmPageImage(int page, bool dark) {
  return CachedNetworkImageProvider(
    rmPageUrl(page, dark),
    cacheManager: rmMushafCache,
  );
}

class RmStore {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static int get lastPage => prefs.getInt('rm_last_page') ?? 1;

  static Future<void> setLastPage(int page) async {
    await prefs.setInt('rm_last_page', page);
  }

  static List<int> get bookmarks {
    return (prefs.getStringList('rm_bookmarks') ?? [])
        .map((e) => int.tryParse(e) ?? 1)
        .toList();
  }

  static Future<void> toggleBookmark(int page) async {
    final list = bookmarks;

    if (list.contains(page)) {
      list.remove(page);
    } else {
      list.add(page);
    }

    list.sort();

    await prefs.setStringList(
      'rm_bookmarks',
      list.map((e) => e.toString()).toList(),
    );
  }
}

class RmQuranPage extends StatefulWidget {
  const RmQuranPage({super.key});

  @override
  State<RmQuranPage> createState() => _RmQuranPageState();
}

class _RmQuranPageState extends State<RmQuranPage> {
  Future<void> openPage(int page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RmMushafReader(page: page),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openSearch() async {
    final page = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => const RmQuranSearchPage(),
      ),
    );

    if (page != null && mounted) {
      openPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = RmStore.lastPage;
    final bookmarks = RmStore.bookmarks;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: openSearch,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ابحث في القرآن أو اكتب رقم الصفحة',
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => openPage(last),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kGreen, kDeep],
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book,
                      color: kGold,
                      size: 34,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'أكمل القراءة',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${rmSurahOfPage(last)} - صفحة $last',
                            style: GoogleFonts.amiri(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const TabBar(
            tabs: [
              Tab(text: 'السور'),
              Tab(text: 'الأجزاء'),
              Tab(text: 'العلامات'),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: rmSurahNames.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            kGreen.withValues(alpha: .12),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: kGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        rmSurahNames[index],
                        style: GoogleFonts.amiri(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'صفحة ${rmSurahPages[index]}',
                      ),
                      trailing: const Icon(
                        Icons.chevron_left,
                      ),
                      onTap: () {
                        openPage(rmSurahPages[index]);
                      },
                    );
                  },
                ),

                ListView.builder(
                  itemCount: rmJuzPages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            kGold.withValues(alpha: .18),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'الجزء ${index + 1}',
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'صفحة ${rmJuzPages[index]}',
                      ),
                      onTap: () {
                        openPage(rmJuzPages[index]);
                      },
                    );
                  },
                ),

                bookmarks.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد علامات مرجعية',
                        ),
                      )
                    : ListView.builder(
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final page = bookmarks[index];

                          return ListTile(
                            leading: const Icon(
                              Icons.bookmark,
                              color: kGold,
                            ),
                            title: Text(
                              'صفحة $page',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              rmSurahOfPage(page),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                              onPressed: () async {
                                await RmStore.toggleBookmark(page);

                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                            onTap: () => openPage(page),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RmMushafReader extends StatefulWidget {
  final int page;

  const RmMushafReader({
    super.key,
    required this.page,
  });

  @override
  State<RmMushafReader> createState() => _RmMushafReaderState();
}

class _RmMushafReaderState extends State<RmMushafReader> {
  late final PageController controller;

  late int page;

  bool controls = true;

  bool night = false;

  @override
  void initState() {
    super.initState();

    page = widget.page;

    controller = PageController(
      initialPage: widget.page - 1,
    );

    RmStore.setLastPage(page);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> showAyahs() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * .88,
          child: _RmAyahSheet(page: page),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final background =
        night ? const Color(0xFF0D0F12) : Colors.white;

    final foreground =
        night ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: controller,
            itemCount: 604,
            backgroundDecoration:
                BoxDecoration(color: background),
            onPageChanged: (index) {
              setState(() {
                page = index + 1;
              });

              RmStore.setLastPage(page);
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider:
                    rmPageImage(index + 1, night),
                minScale:
                    PhotoViewComputedScale.contained,
                maxScale:
                    PhotoViewComputedScale.contained * 3,
                onTapUp: (_, __, ___) {
                  setState(() {
                    controls = !controls;
                  });
                },
              );
            },
          ),

          if (controls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: background.withValues(alpha: .94),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: foreground,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          '${rmSurahOfPage(page)} - صفحة $page',
                          style: GoogleFonts.amiri(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: foreground,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.menu_book,
                          color: kGold,
                        ),
                        onPressed: showAyahs,
                      ),
                      IconButton(
                        icon: Icon(
                          RmStore.bookmarks.contains(page)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: kGold,
                        ),
                        onPressed: () async {
                          await RmStore.toggleBookmark(page);

                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          night
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: foreground,
                        ),
                        onPressed: () {
                          setState(() {
                            night = !night;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RmAyahSheet extends StatelessWidget {
  final int page;

  const _RmAyahSheet({
    required this.page,
  });

  Future<List<dynamic>> load() async {
    final response = await http.get(
      Uri.parse(
        'https://api.alquran.cloud/v1/page/$page/quran-uthmani',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    return json['data']['ayahs'] as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'تعذر تحميل آيات الصفحة.\n'
                'تأكد من اتصال الإنترنت ثم حاول مرة أخرى.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final ayahs = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                8,
                8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: kGold,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'آيات صفحة $page',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: ayahs.length,
                itemBuilder: (context, index) {
                  final ayah = ayahs[index];

                  final text =
                      ayah['text']?.toString() ?? '';

                  final number =
                      ayah['numberInSurah']?.toString() ??
                          '';

                  final surah =
                      ayah['surah']?['name']?.toString() ??
                          '';

                  return Card(
                    margin:
                        const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$surah - آية $number',
                                  style: const TextStyle(
                                    color: kGreen,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                ),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: text,
                                    ),
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'تم نسخ الآية',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                ),
                                onPressed: () {
                                  Share.share(
                                    '﴿$text﴾\n'
                                    '$surah - آية $number\n'
                                    'رفيق المسلم',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class RmQuranSearchPage extends StatefulWidget {
  const RmQuranSearchPage({super.key});

  @override
  State<RmQuranSearchPage> createState() =>
      _RmQuranSearchPageState();
}

class _RmQuranSearchPageState
    extends State<RmQuranSearchPage> {
  final controller = TextEditingController();

  List<dynamic> results = [];

  bool loading = false;

  String message = 'اكتب كلمة للبحث';

  Future<void> search() async {
    final query = controller.text.trim();

    if (query.isEmpty) return;

    final page = int.tryParse(query);

    if (page != null) {
      if (page >= 1 && page <= 604) {
        if (mounted) {
          Navigator.pop(context, page);
        }
      }

      return;
    }

    setState(() {
      loading = true;
      results = [];
      message = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.alquran.cloud/v1/search/'
          '${Uri.encodeComponent(query)}/all/quran-uthmani',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception();
      }

      final json = jsonDecode(response.body);

      final data = json['data'];

      if (data is Map && data['matches'] is List) {
        results = data['matches'];
      }

      if (results.isEmpty) {
        message = 'لا توجد نتائج';
      }
    } catch (_) {
      message = 'تعذر تنفيذ البحث. تحقق من الإنترنت.';
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => search(),
          decoration: const InputDecoration(
            hintText: 'ابحث في القرآن...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: search,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : results.isEmpty
              ? Center(
                  child: Text(message),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];

                    final text =
                        item['text']?.toString() ?? '';

                    final number =
                        item['numberInSurah']?.toString() ??
                            '';

                    final surah =
                        item['surah']?['name']?.toString() ??
                            '';

                    final page =
                        item['page'] is int
                            ? item['page'] as int
                            : null;

                    return ListTile(
                      title: Text(
                        text,
                        style: GoogleFonts.amiri(
                          fontSize: 19,
                        ),
                      ),
                      subtitle: Text(
                        '$surah - آية $number'
                        '${page == null ? '' : ' - صفحة $page'}',
                      ),
                      onTap: page == null
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                page,
                              );
                            },
                    );
                  },
                ),
    );
  }
}
// ===============================
// القسم الثالث: الأذكار والحج
// ===============================

class RmDhikrItem {
  final String text;
  final int count;

  const RmDhikrItem({
    required this.text,
    required this.count,
  });
}

class RmAdhkarPage extends StatefulWidget {
  const RmAdhkarPage({super.key});

  @override
  State<RmAdhkarPage> createState() =>
      _RmAdhkarPageState();
}

class _RmAdhkarPageState
    extends State<RmAdhkarPage> {
  final Map<String, List<RmDhikrItem>> categories = {
    'أذكار الصباح': const [
      RmDhikrItem(
        text:
            'أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 1,
      ),
      RmDhikrItem(
        text:
            'اللهم بك أصبحنا وبك أمسينا، وبك نحيا وبك نموت وإليك النشور.',
        count: 1,
      ),
      RmDhikrItem(
        text:
            'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.',
        count: 3,
      ),
      RmDhikrItem(
        text:
            'أعوذ بكلمات الله التامات من شر ما خلق.',
        count: 3,
      ),
    ],
    'أذكار المساء': const [
      RmDhikrItem(
        text:
            'أمسينا وأمسى الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 1,
      ),
      RmDhikrItem(
        text:
            'اللهم بك أمسينا وبك أصبحنا، وبك نحيا وبك نموت وإليك المصير.',
        count: 1,
      ),
      RmDhikrItem(
        text:
            'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.',
        count: 3,
      ),
    ],
    'أذكار النوم': const [
      RmDhikrItem(
        text:
            'باسمك اللهم أموت وأحيا.',
        count: 1,
      ),
      RmDhikrItem(
        text:
            'اللهم قني عذابك يوم تبعث عبادك.',
        count: 3,
      ),
    ],
    'بعد الصلاة': const [
      RmDhikrItem(
        text:
            'أستغفر الله.',
        count: 3,
      ),
      RmDhikrItem(
        text:
            'اللهم أنت السلام ومنك السلام تباركت يا ذا الجلال والإكرام.',
        count: 1,
      ),
      RmDhikrItem(
        text:
            'سبحان الله والحمد لله والله أكبر.',
        count: 33,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: const Icon(
              Icons.favorite,
              color: kGold,
            ),
            title: Text(
              entry.key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            children: [
              for (final dhikr in entry.value)
                RmDhikrCard(dhikr: dhikr),
            ],
          ),
        );
      },
    );
  }
}

class RmDhikrCard extends StatefulWidget {
  final RmDhikrItem dhikr;

  const RmDhikrCard({
    super.key,
    required this.dhikr,
  });

  @override
  State<RmDhikrCard> createState() =>
      _RmDhikrCardState();
}

class _RmDhikrCardState extends State<RmDhikrCard> {
  late int remaining;

  @override
  void initState() {
    super.initState();
    remaining = widget.dhikr.count;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        14,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: remaining > 0
            ? () {
                setState(() {
                  remaining--;
                });
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: .35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                widget.dhikr.text,
                style: GoogleFonts.amiri(
                  fontSize: 19,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    remaining == 0
                        ? 'تم'
                        : 'المتبقي: $remaining',
                    style: TextStyle(
                      color: remaining == 0
                          ? kGreen
                          : Theme.of(context)
                              .colorScheme
                              .primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (remaining == 0)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      onPressed: () {
                        setState(() {
                          remaining =
                              widget.dhikr.count;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RmHajjPage extends StatelessWidget {
  const RmHajjPage({super.key});

  static const steps = [
    (
      'الإحرام',
      'النية بالحج أو العمرة من الميقات، ثم التلبية والالتزام بأحكام الإحرام.'
    ),
    (
      'الطواف',
      'الطواف حول الكعبة سبعة أشواط، يبدأ الشوط من الحجر الأسود وينتهي عنده.'
    ),
    (
      'السعي',
      'السعي بين الصفا والمروة سبعة أشواط.'
    ),
    (
      'الوقوف بعرفة',
      'الوقوف بعرفة في اليوم التاسع من ذي الحجة، وهو من أعظم أركان الحج.'
    ),
    (
      'المبيت بمزدلفة',
      'بعد الانصراف من عرفة يتوجه الحاج إلى مزدلفة وفق أحكام الحج.'
    ),
    (
      'رمي الجمرات',
      'رمي الجمرات في أيام التشريق وفق النسك الذي يؤديه الحاج.'
    ),
    (
      'الحلق أو التقصير',
      'بعد إتمام المناسك التي يترتب عليها التحلل يحلق الحاج أو يقصر.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor:
                  kGreen.withValues(alpha: .12),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: kGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              step.$1,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  18,
                ),
                child: Text(
                  step.$2,
                  style: const TextStyle(
                    height: 1.7,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RmSettingsPage extends StatelessWidget {
  const RmSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: kGold,
            ),
            title: const Text(
              'الوضع الليلي',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              dark ? 'مفعّل من إعدادات الجهاز' : 'الوضع الفاتح',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: kGreen,
            ),
            title: const Text(
              'رفيق المسلم',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'تطبيق إسلامي شامل',
            ),
          ),
        ),
      ],
    );
  }
}
// ===============================
// القسم الرابع: الصلاة والقبلة
// ===============================

class RmPrayerPage extends StatefulWidget {
  const RmPrayerPage({super.key});

  @override
  State<RmPrayerPage> createState() =>
      _RmPrayerPageState();
}

class _RmPrayerPageState
    extends State<RmPrayerPage> {
  Map<String, dynamic>? timings;

  bool loading = true;

  String error = '';

  @override
  void initState() {
    super.initState();
    loadPrayerTimes();
  }

  Future<void> loadPrayerTimes() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final service =
          await Geolocator.isLocationServiceEnabled();

      if (!service) {
        throw Exception(
          'يرجى تشغيل خدمة الموقع GPS',
        );
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        throw Exception(
          'تم رفض إذن الموقع',
        );
      }

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&method=5',
      );

      final response =
          await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception();
      }

      final json = jsonDecode(response.body);

      setState(() {
        timings =
            Map<String, dynamic>.from(
          json['data']['timings'],
        );

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off,
                size: 55,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: loadPrayerTimes,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'إعادة المحاولة',
                ),
              ),
            ],
          ),
        ),
      );
    }

    const prayers = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    return RefreshIndicator(
      onRefresh: loadPrayerTimes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kGreen, kDeep],
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(22),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.mosque,
                  color: kGold,
                  size: 42,
                ),
                SizedBox(height: 8),
                Text(
                  'مواقيت الصلاة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'بحسب موقعك الحالي',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          for (final entry in prayers.entries)
            Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: kGold,
                ),
                title: Text(
                  entry.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                trailing: Text(
                  timings?[entry.key]?.toString() ??
                      '--:--',
                  style: const TextStyle(
                    color: kGreen,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RmQiblaPage extends StatefulWidget {
  const RmQiblaPage({super.key});

  @override
  State<RmQiblaPage> createState() =>
      _RmQiblaPageState();
}

class _RmQiblaPageState
    extends State<RmQiblaPage> {
  late Future<bool?> support;

  @override
  void initState() {
    super.initState();

    support =
        FlutterQiblah.androidDeviceSensorSupport();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: support,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError ||
            snapshot.data != true) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'جهازك لا يدعم حساس البوصلة المطلوب '
                'لتحديد اتجاه القبلة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<QiblahDirection>(
          stream: FlutterQiblah.qiblahStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final direction = snapshot.data!;

            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.explore,
                    size: 65,
                    color: kGold,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'اتجاه القبلة',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${direction.qiblah.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 22,
                      color: kGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Transform.rotate(
                    angle:
                        direction.qiblah * pi / 180 * -1,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kGreen,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        size: 170,
                        color: kGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'حرّك الهاتف ببطء للحصول على قراءة أدق',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
// ===============================
// القسم الرابع: الصلاة والقبلة
// ===============================

class RmPrayerPage extends StatefulWidget {
  const RmPrayerPage({super.key});

  @override
  State<RmPrayerPage> createState() =>
      _RmPrayerPageState();
}

class _RmPrayerPageState
    extends State<RmPrayerPage> {
  Map<String, dynamic>? timings;

  bool loading = true;

  String error = '';

  @override
  void initState() {
    super.initState();
    loadPrayerTimes();
  }

  Future<void> loadPrayerTimes() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final service =
          await Geolocator.isLocationServiceEnabled();

      if (!service) {
        throw Exception(
          'يرجى تشغيل خدمة الموقع GPS',
        );
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        throw Exception(
          'تم رفض إذن الموقع',
        );
      }

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&method=5',
      );

      final response =
          await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception();
      }

      final json = jsonDecode(response.body);

      setState(() {
        timings =
            Map<String, dynamic>.from(
          json['data']['timings'],
        );

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off,
                size: 55,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: loadPrayerTimes,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'إعادة المحاولة',
                ),
              ),
            ],
          ),
        ),
      );
    }

    const prayers = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    return RefreshIndicator(
      onRefresh: loadPrayerTimes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kGreen, kDeep],
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(22),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.mosque,
                  color: kGold,
                  size: 42,
                ),
                SizedBox(height: 8),
                Text(
                  'مواقيت الصلاة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'بحسب موقعك الحالي',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          for (final entry in prayers.entries)
            Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: kGold,
                ),
                title: Text(
                  entry.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                trailing: Text(
                  timings?[entry.key]?.toString() ??
                      '--:--',
                  style: const TextStyle(
                    color: kGreen,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RmQiblaPage extends StatefulWidget {
  const RmQiblaPage({super.key});

  @override
  State<RmQiblaPage> createState() =>
      _RmQiblaPageState();
}

class _RmQiblaPageState
    extends State<RmQiblaPage> {
  late Future<bool?> support;

  @override
  void initState() {
    super.initState();

    support =
        FlutterQiblah.androidDeviceSensorSupport();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: support,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError ||
            snapshot.data != true) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'جهازك لا يدعم حساس البوصلة المطلوب '
                'لتحديد اتجاه القبلة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<QiblahDirection>(
          stream: FlutterQiblah.qiblahStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final direction = snapshot.data!;

            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.explore,
                    size: 65,
                    color: kGold,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'اتجاه القبلة',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${direction.qiblah.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 22,
                      color: kGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Transform.rotate(
                    angle:
                        direction.qiblah * pi / 180 * -1,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kGreen,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        size: 170,
                        color: kGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'حرّك الهاتف ببطء للحصول على قراءة أدق',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
// ===============================
// القسم الخامس: التطبيق الرئيسي
// ===============================

class RmHomePage extends StatefulWidget {
  const RmHomePage({super.key});

  @override
  State<RmHomePage> createState() =>
      _RmHomePageState();
}

class _RmHomePageState
    extends State<RmHomePage> {
  int selectedIndex = 0;

  late final List<Widget> pages;

  final titles = const [
    'رفيق المسلم - القرآن الكريم',
    'حصن المسلم والأذكار',
    'مواقيت الصلاة',
    'مناسك الحج والعمرة',
    'اتجاه القبلة',
  ];

  @override
  void initState() {
    super.initState();

    pages = const [
      RmQuranPage(),
      RmAdhkarPage(),
      RmPrayerPage(),
      RmHajjPage(),
      RmQiblaPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        actions: [
          if (selectedIndex == 0)
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(
                Icons.settings_outlined,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const RmSettingsPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.menu_book_outlined,
            ),
            selectedIcon: Icon(
              Icons.menu_book,
            ),
            label: 'القرآن',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.favorite_border,
            ),
            selectedIcon: Icon(
              Icons.favorite,
            ),
            label: 'الأذكار',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.access_time,
            ),
            selectedIcon: Icon(
              Icons.access_time_filled,
            ),
            label: 'الصلاة',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.mosque_outlined,
            ),
            selectedIcon: Icon(
              Icons.mosque,
            ),
            label: 'الحج',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.explore_outlined,
            ),
            selectedIcon: Icon(
              Icons.explore,
            ),
            label: 'القبلة',
          ),
        ],
      ),
    );
  }
}

class RmApp extends StatelessWidget {
  const RmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رفيق المسلم',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const RmHomePage(),
    );
  }
}

// إذا كان لديك main() في القسم الأول، لا تضف
// main() آخر.
// وإذا لم يكن موجوداً، استخدم هذا:

Future<void> rmStartApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RmStore.init();

  runApp(const RmApp());
}