import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'adhkar.dart';
import 'notify.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notify.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'رفيق المسلم',
        theme: ThemeData(
            colorSchemeSeed: const Color(0xFF0B6E4F), useMaterial3: true),
        builder: (c, w) =>
            Directionality(textDirection: TextDirection.rtl, child: w!),
        home: const Home(),
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
  final titles = ['القرآن الكريم', 'الأذكار', 'مواقيت الصلاة', 'الحج والعمرة', 'القبلة'];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(titles[i]), centerTitle: true),
        body: pages[i],
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.menu_book), label: 'القرآن'),
            NavigationDestination(icon: Icon(Icons.favorite), label: 'الأذكار'),
            NavigationDestination(icon: Icon(Icons.access_time), label: 'المواقيت'),
            NavigationDestination(icon: Icon(Icons.mosque), label: 'الحج'),
            NavigationDestination(icon: Icon(Icons.explore), label: 'القبلة'),
          ],
        ),
      );
}

// ---------------- القرآن ----------------
class QuranPage extends StatelessWidget {
  const QuranPage({super.key});
  Future<List> load() async {
    final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
    return jsonDecode(r.body)['data'];
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List>(
        future: load(),
        builder: (c, s) {
          if (s.hasError) return const Center(child: Text('تعذر التحميل، تأكد من الإنترنت'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: s.data!.length,
            itemBuilder: (c, k) {
              final x = s.data![k];
              return ListTile(
                leading: CircleAvatar(child: Text('${x['number']}')),
                title: Text(x['name']),
                subtitle: Text('${x['numberOfAyahs']} آية'),
                onTap: () => Navigator.push(
                    c,
                    MaterialPageRoute(
                        builder: (_) => SurahPage(x['number'], x['name']))),
              );
            },
          );
        },
      );
}

class SurahPage extends StatelessWidget {
  final int n;
  final String name;
  const SurahPage(this.n, this.name, {super.key});
  Future<List> load() async {
    final r = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/surah/$n/quran-uthmani'));
    return jsonDecode(r.body)['data']['ayahs'];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(name), centerTitle: true),
        body: FutureBuilder<List>(
          future: load(),
          builder: (c, s) {
            if (s.hasError) return const Center(child: Text('تعذر التحميل'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final text = s.data!
                .map((a) => '${a['text']} ﴿${a['numberInSurah']}﴾')
                .join(' ');
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(text,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 26, height: 2.2)),
            );
          },
        ),
      );
}

// ---------------- مواقيت الصلاة ----------------
class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key});
  static const names = {
    'Fajr': 'الفجر',
    'Sunrise': 'الشروق',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء'
  };

  Future<Map> load() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition();
    Notify.schedule(pos.latitude, pos.longitude);
    final r = await http.get(Uri.parse(
        'https://api.aladhan.com/v1/timings?latitude=${pos.latitude}&longitude=${pos.longitude}&method=4'));
    return jsonDecode(r.body)['data']['timings'];
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map>(
        future: load(),
        builder: (c, s) {
          if (s.hasError) return const Center(child: Text('فعّل الموقع والإنترنت ثم أعد المحاولة'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(12),
            children: names.entries
                .map((e) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(e.value, style: const TextStyle(fontSize: 20)),
                        trailing: Text(s.data![e.key],
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ))
                .toList(),
          );
        },
      );
}

// ---------------- الحج والعمرة ----------------
class HajjPage extends StatefulWidget {
  const HajjPage({super.key});
  @override
  State<HajjPage> createState() => _HajjPageState();
}

class _HajjPageState extends State<HajjPage> {
  final umrah = [
    'الإحرام من الميقات والنية (لبيك اللهم عمرة)',
    'التلبية: لبيك اللهم لبيك، لبيك لا شريك لك لبيك',
    'الطواف بالكعبة سبع أشواط',
    'صلاة ركعتين خلف مقام إبراهيم',
    'شرب ماء زمزم',
    'السعي بين الصفا والمروة سبعة أشواط',
    'الحلق أو التقصير',
  ];
  final hajj = [
    'اليوم 8 (التروية): الإحرام والذهاب إلى منى',
    'اليوم 9 (عرفة): الوقوف بعرفة حتى الغروب',
    'مزدلفة: المبيت وجمع الحصى',
    'اليوم 10: رمي جمرة العقبة، النحر، الحلق، طواف الإفاضة والسعي',
    'أيام التشريق: المبيت بمنى ورمي الجمرات الثلاث',
    'طواف الوداع',
  ];
  late final doneU = List.filled(umrah.length, false);
  late final doneH = List.filled(hajj.length, false);

  Widget section(String title, List<String> l, List<bool> d) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          for (var k = 0; k < l.length; k++)
            CheckboxListTile(
              value: d[k],
              onChanged: (v) => setState(() => d[k] = v!),
              title: Text(l[k]),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) => ListView(children: [
        section('خطوات العمرة', umrah, doneU),
        section('مناسك الحج', hajj, doneH),
      ]);
}

// ---------------- القبلة ----------------
class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: Geolocator.requestPermission(),
        builder: (c, p) {
          if (!p.hasData) return const Center(child: CircularProgressIndicator());
          return StreamBuilder<QiblahDirection>(
            stream: FlutterQiblah.qiblahStream,
            builder: (c, s) {
              if (s.hasError) return const Center(child: Text('فعّل الموقع وحساسات الجوال'));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final angle = s.data!.qiblah * (pi / 180) * -1;
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Transform.rotate(
                      angle: angle,
                      child: Icon(Icons.navigation,
                          size: 200, color: Theme.of(c).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text('${s.data!.offset.toStringAsFixed(0)}° اتجاه القبلة',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('ثبّت الجوال أفقياً وحرّكه حتى يشير السهم للأعلى'),
                ]),
              );
            },
          );
        },
      );
}
