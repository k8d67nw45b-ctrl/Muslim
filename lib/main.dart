import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adhkar.dart';
import 'notify.dart';

const kGreen = Color(0xFF0B6E4F);
const kDeep = Color(0xFF06382A);
const kGold = Color(0xFFC9A227);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final cs = ColorScheme.fromSeed(seedColor: kGreen, brightness: b);
  final base = ThemeData(colorScheme: cs, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor:
        dark ? const Color(0xFF0C1512) : const Color(0xFFF3F6F2),
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : kDeep),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF111C18) : Colors.white,
      indicatorColor: kGold.withValues(alpha: .28),
      labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  await AppNotify.init();
  await AppNotify.scheduleDhikrPeriodic();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'رفيق المسلم',
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        builder: (c, w) => Title(
          title: 'رفيق المسلم',
          color: kGreen,
          child: Directionality(textDirection: TextDirection.rtl, child: w!),
        ),
        home: const Home(),
      );
}

class StarBadge extends StatelessWidget {
  final String label;
  final double size;
  const StarBadge(this.label, {super.key, this.size = 46});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    Widget sq(double a) => Transform.rotate(
        angle: a,
        child: Container(
            width: size * .72,
            height: size * .72,
            decoration: BoxDecoration(
                color: c.withValues(alpha: .12),
                border: Border.all(color: c.withValues(alpha: .5)),
                borderRadius: BorderRadius.circular(6))));
    return SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          sq(0),
          sq(pi / 4),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: c)),
        ]));
  }
}

class Msg extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const Msg(this.text, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton.tonal(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ]),
        ),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int i = 0;
  final pages = const [
    QuranPage(),
    AdhkarPage(),
    PrayerPage(),
    HajjPage(),
    QiblaPage()
  ];
  final titles = [
    'رفيق المسلم - القرآن الكريم',
    'الأذكار اليومية',
    'مواقيت الصلاة',
    'الحج والعمرة',
    'القبلة'
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(titles[i])),
        body: pages[i],
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'القرآن'),
            NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'الأذكار'),
            NavigationDestination(
                icon: Icon(Icons.access_time),
                selectedIcon: Icon(Icons.access_time_filled),
                label: 'المواقيت'),
            NavigationDestination(
                icon: Icon(Icons.mosque_outlined),
                selectedIcon: Icon(Icons.mosque),
                label: 'الحج'),
            NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'القبلة'),
          ],
        ),
      );
}

const surahNames = [
  'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف',
  'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
  'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون',
  'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
  'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر',
  'غافر', 'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد',
  'الفتح', 'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
  'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة',
  'المنافقون', 'التغابن', 'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة',
  'المعارج', 'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة', 'الإنسان',
  'المرسلات', 'النبأ', 'النازعات', 'عبس', 'التكوير', 'الانفطار', 'المطففين',
  'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
  'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق', 'القدر', 'البينة',
  'الزلزلة', 'العاديات', 'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
  'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص',
  'الفلق', 'الناس'
];

const surahPages = [
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
  603, 604, 604, 604
];

const juzPages = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282,
  302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582
];

String surahOfPage(int p) {
  var k = 0;
  for (var i = 0; i < surahPages.length; i++) {
    if (surahPages[i] <= p) k = i;
  }
  return surahNames[k];
}

int juzOfPage(int p) {
  var k = 0;
  for (var i = 0; i < juzPages.length; i++) {
    if (juzPages[i] <= p) k = i;
  }
  return k + 1;
}

String pageUrl(int p, bool dark) =>
    'https://cdn.jsdelivr.net/gh/SakinaDevGroup/mushaf-madani-cdn@main/${dark ? 'dark' : 'light'}/p$p.png';

class Store {
  static late SharedPreferences p;
  static Future<void> init() async => p = await SharedPreferences.getInstance();
  static int get last => p.getInt('last') ?? 1;
  static set last(int v) => p.setInt('last', v);
  static List<int> get marks =>
      (p.getStringList('marks') ?? []).map(int.parse).toList();
  static void toggleMark(int page) {
    final m = marks;
    m.contains(page) ? m.remove(page) : m.add(page);
    m.sort();
    p.setStringList('marks', m.map((e) => '$e').toList());
  }
}

final mushafCache = cache.CacheManager(cache.Config('mushafPagesHighRes',
    stalePeriod: const Duration(days: 3650), maxNrOfCacheObjects: 4000));

ImageProvider pageImg(int p, bool dark) =>
    CachedNetworkImageProvider(pageUrl(p, dark), cacheManager: mushafCache);

class Offline {
  static final tick = ValueNotifier<int>(0);
  static String? running;
  static bool cancel = false;
  static int done = 0;
  static int failed = 0;

  static bool has(String t) => Store.p.getBool('dl_$t') ?? false;
  static void stop() => cancel = true;

  static Future<void> download(String t) async {
    if (running != null) return;
    running = t;
    cancel = false;
    done = 0;
    failed = 0;
    tick.value++;
    final dark = t == 'dark';
    for (var start = 1; start <= 604 && !cancel; start += 4) {
      final batch = [for (var p = start; p < start + 4 && p <= 604; p++) p];
      await Future.wait(batch.map((p) async {
        final url = pageUrl(p, dark);
        try {
          if (await mushafCache.getFileFromCache(url) == null) {
            await mushafCache.downloadFile(url);
          }
        } catch (_) {
          try {
            await mushafCache.downloadFile(url);
          } catch (_) {
            failed++;
          }
        }
        done++;
      }));
      tick.value++;
    }
    if (!cancel && failed == 0) Store.p.setBool('dl_$t', true);
    running = null;
    tick.value++;
  }
}

class DownloadBar extends StatelessWidget {
  const DownloadBar({super.key});

  void choose(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('تحميل المصحف بجودة عالية وبدون إنترنت',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          for (final t in ['light', 'dark'])
            ListTile(
              leading: Icon(t == 'dark' ? Icons.dark_mode : Icons.light_mode),
              title: Text(t == 'dark' ? 'الصفحات الداكنة' : 'الصفحات الفاتحة'),
              subtitle: Text(Offline.has(t) ? 'محمّلة' : 'غير محمّلة'),
              trailing: Icon(Offline.has(t) ? Icons.check_circle : Icons.download),
              onTap: () {
                Navigator.pop(c);
                Offline.download(t);
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: Offline.tick,
        builder: (c, _, __) {
          final cs = Theme.of(c).colorScheme;
          final run = Offline.running;
          final full = Offline.has('light') && Offline.has('dark');
          final text = run != null
              ? 'جارٍ التحميل عالي الدقة: ${Offline.done} من 604'
              : full
                  ? 'المصحف عالي الدقة محمّل ويعمل بدون إنترنت'
                  : 'حمّل المصحف عالي الدقة بدون إنترنت';
          return InkWell(
            onTap: run == null ? () => choose(c) : null,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: .6)),
              ),
              child: Row(children: [
                Icon(full ? Icons.download_done : Icons.download_for_offline_outlined,
                    color: full ? cs.primary : kGold),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
              ]),
            ),
          );
        },
      );
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});
  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  Future<void> open(int page) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => MushafReader(page)));
    if (mounted) setState(() {});
  }

  Future<void> search() async {
    final p = await Navigator.push<int>(
        context, MaterialPageRoute(builder: (_) => const SearchPage()));
    if (p != null) open(p);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final last = Store.last;
    final marks = Store.marks;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        InkWell(
          onTap: search,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: .6)),
            ),
            child: Row(children: [
              Icon(Icons.search, color: cs.outline),
              const SizedBox(width: 10),
              Text('ابحث في القرآن أو اكتب رقم صفحة', style: TextStyle(color: cs.outline)),
            ]),
          ),
        ),
        InkWell(
          onTap: () => open(last),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [kGreen, kDeep]),
            ),
            child: Row(children: [
              const Icon(Icons.menu_book, color: kGold, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('أكمل القراءة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('${surahOfPage(last)}، صفحة $last',
                      style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ),
              const Icon(Icons.chevron_left, color: Colors.white),
            ]),
          ),
        ),
        const DownloadBar(),
        TabBar(
          tabs: const [Tab(text: 'السور'), Tab(text: 'الأجزاء'), Tab(text: 'العلامات')],
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          labelColor: cs.primary,
          indicatorColor: kGold,
        ),
        Expanded(
          child: TabBarView(children: [
            ListView.builder(
              itemCount: surahNames.length,
              itemBuilder: (c, k) => ListTile(
                leading: StarBadge('${k + 1}'),
                title: Text(surahNames[k], style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.w700)),
                subtitle: Text('صفحة ${surahPages[k]}'),
                onTap: () => open(surahPages[k]),
              ),
            ),
            ListView.builder(
              itemCount: juzPages.length,
              itemBuilder: (c, k) => ListTile(
                leading: StarBadge('${k + 1}'),
                title: Text('الجزء ${k + 1}', style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.w700)),
                subtitle: Text('صفحة ${juzPages[k]}'),
                onTap: () => open(juzPages[k]),
              ),
            ),
            marks.isEmpty
                ? const Center(child: Text('لا توجد علامات مرجعية محفوظة'))
                : ListView.builder(
                    itemCount: marks.length,
                    itemBuilder: (c, k) => ListTile(
                      leading: const Icon(Icons.bookmark, color: kGold, size: 30),
                      title: Text('صفحة ${marks[k]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${surahOfPage(marks[k])}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => Store.toggleMark(marks[k])),
                      ),
                      onTap: () => open(marks[k]),
                    ),
                  ),
          ]),
        ),
      ]),
    );
  }
}

class MushafReader extends StatefulWidget {
  final int page;
  const MushafReader(this.page, {super.key});
  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late final PageController pc;
  late int page;
  bool chrome = true;
  bool? nightOv;

  bool get night => nightOv ?? Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    page = widget.page;
    pc = PageController(initialPage: page - 1);
    Store.last = page;
  }

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  void showTafsir(int currentPage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.menu_book, color: kGold),
              const SizedBox(width: 10),
              Text('تفسير صفحة $currentPage (${surahOfPage(currentPage)})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
            ]),
            const Divider(),
            Expanded(
              child: ListView(
                children: const [
                  Text('تفسير الجلالين والميسر:', style: TextStyle(fontWeight: FontWeight.bold, color: kGreen, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('هذا هو التفسير المعتمد والميسر لآيات هذه الصفحة المباركة...', style: TextStyle(fontSize: 15, height: 1.7)),
                  SizedBox(height: 16),
                  Text('تفسير الطبري (جامع البيان):', style: TextStyle(fontWeight: FontWeight.bold, color: kGreen, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('تفاصيل تأويل الآيات الكريمة حسب الطبري...', style: TextStyle(fontSize: 15, height: 1.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = night ? const Color(0xFF0D0F12) : Colors.white;
    final fg = night ? Colors.white : Colors.black87;
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        PhotoViewGallery.builder(
          pageController: pc,
          itemCount: 604,
          backgroundDecoration: BoxDecoration(color: bg),
          onPageChanged: (i) {
            setState(() => page = i + 1);
            Store.last = i + 1;
          },
          builder: (c, i) => PhotoViewGalleryPageOptions(
            imageProvider: pageImg(i + 1, night),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.contained * 3,
            onTapUp: (_, __, ___) => setState(() => chrome = !chrome),
          ),
        ),
        if (chrome)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Material(
              color: bg.withValues(alpha: .94),
              child: SafeArea(
                bottom: false,
                child: Row(children: [
                  BackButton(color: fg),
                  Expanded(
                    child: Text('${surahOfPage(page)}، صفحة $page',
                        style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold, color: fg)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu_book_outlined, color: kGold),
                    tooltip: 'التفسير',
                    onPressed: () => showTafsir(page),
                  ),
                  IconButton(
                    icon: Icon(Store.marks.contains(page) ? Icons.bookmark : Icons.bookmark_border, color: kGold),
                    tooltip: 'علامة مرجعية',
                    onPressed: () => setState(() => Store.toggleMark(page)),
                  ),
                  IconButton(
                    icon: Icon(night ? Icons.light_mode : Icons.dark_mode, color: fg),
                    onPressed: () => setState(() => nightOv = !night),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ctl = TextEditingController();
  List results = [];
  bool loading = false;
  String? msg = 'اكتب كلمة للبحث أو رقم صفحة';

  Future<void> run(String raw) async {
    final q = raw.replaceAll(RegExp('[\u064B-\u065F\u0670]'), '').trim();
    if (q.isEmpty) return;
    final n = int.tryParse(q);
    if (n != null && n >= 1 && n <= 604) {
      Navigator.pop(context, n);
      return;
    }
    setState(() {
      loading = true;
      msg = null;
      results = [];
    });
    try {
      final r = await http.get(Uri.parse(
          'https://api.alquran.cloud/v1/search/${Uri.encodeComponent(q)}/all/quran-simple'));
      final d = jsonDecode(r.body)['data'];
      if (d is Map) results = d['matches'];
      if (results.isEmpty) msg = 'لا توجد نتائج';
    } catch (_) {
      msg = 'تعذر الاتصال للبحث';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: ctl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: run,
            decoration: const InputDecoration(hintText: 'ابحث...', border: InputBorder.none),
          ),
          actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => run(ctl.text))],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : msg != null
                ? Center(child: Text(msg!))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (c, k) {
                      final m = results[k];
                      final sn = m['surah']['number'] as int;
                      return ListTile(
                        title: Text(m['text'], style: GoogleFonts.amiri(fontSize: 18)),
                        subtitle: Text('${surahNames[sn - 1]} - آية ${m['numberInSurah']}'),
                        onTap: () async {
                          int p = surahPages[sn - 1];
                          try {
                            final res = await http.get(Uri.parse(
                                'https://api.alquran.cloud/v1/ayah/$sn:${m['numberInSurah']}'));
                            p = jsonDecode(res.body)['data']['page'];
                          } catch (_) {}
                          if (mounted) Navigator.pop(context, p);
                        },
                      );
                    },
                  ),
      );
}

class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('مواقيت الصلاة'));
}

class HajjPage extends StatelessWidget {
  const HajjPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('مناسك الحج والعمرة'));
}

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('بوصلة القبلة'));
}
