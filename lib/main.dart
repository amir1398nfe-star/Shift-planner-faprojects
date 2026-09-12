import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedLang = prefs.getString('app_lang');
  runApp(ShiftPlannerApp(initialLang: savedLang));
}

class ShiftPlannerApp extends StatefulWidget {
  final String? initialLang;
  const ShiftPlannerApp({super.key, this.initialLang});

  static void setLocale(BuildContext context, Locale newLocale) {
    _ShiftPlannerAppState? state = context.findAncestorStateOfType<_ShiftPlannerAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<ShiftPlannerApp> createState() => _ShiftPlannerAppState();
}

class _ShiftPlannerAppState extends State<ShiftPlannerApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    if (widget.initialLang != null) {
      _locale = Locale(widget.initialLang!);
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shift & Work Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      locale: _locale,
      supportedLocales: const [
        Locale('fa', ''),
        Locale('en', ''),
        Locale('de', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _locale == null ? const LanguageSelectionScreen() : const HomeScreen(),
    );
  }
}

// ------------------- صفحه انتخاب زبان -------------------
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, String langCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', langCode);
    if (context.mounted) {
      ShiftPlannerApp.setLocale(context, Locale(langCode));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text('لطفاً زبان خود را انتخاب کنید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Please select your language / Bitte زبان wählen'),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => _selectLanguage(context, 'fa'),
                child: const Text('فارسی (Persian)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => _selectLanguage(context, 'en'),
                child: const Text('English'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => _selectLanguage(context, 'de'),
                child: const Text('Deutsch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- صفحه اصلی و تقویم -------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Jalali _selectedMonth = Jalali.now();
  final Map<String, Map<String, dynamic>> _dayLogs = {}; // کلید: YYYY-MM-DD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقویم کاری و شیفت‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsScreen(logs: _dayLogs)));
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildMonthHeader(),
          Expanded(child: _buildJalaliGrid()),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _selectedMonth = _selectedMonth.addMonths(-1)),
          ),
          Text(
            '${_selectedMonth.formatter.mN} ${_selectedMonth.year}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _selectedMonth = _selectedMonth.addMonths(1)),
          ),
        ],
      ),
    );
  }

  Widget _buildJalaliGrid() {
    int daysInMonth = _selectedMonth.monthLength;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        int day = index + 1;
        String dateKey = '${_selectedMonth.year}-${_selectedMonth.month}-$day';
        var log = _dayLogs[dateKey] ?? {};

        return InkWell(
          onTap: () => _showEditDialog(dateKey, day),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: log.isNotEmpty ? Colors.indigo.shade50 : Colors.grey.shade100,
              border: Border.all(color: log.isNotEmpty ? Colors.indigo : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (log['overtime'] != null && log['overtime'] > 0)
                  Text('+${log['overtime']}h', style: const TextStyle(fontSize: 10, color: Colors.green)),
                if (log['leaveType'] != null)
                  Text('${log['leaveType']}', style: const TextStyle(fontSize: 9, color: Colors.orange)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(String dateKey, int day) {
    final overtimeController = TextEditingController(text: _dayLogs[dateKey]?['overtime']?.toString() ?? '');
    String leaveType = _dayLogs[dateKey]?['leaveType'] ?? 'بدون مرخصی';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Text('تنظیمات روز $day ${_selectedMonth.formatter.mN}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: overtimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'اضافه‌کاری (ساعت)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: leaveType,
                items: ['بدون مرخصی', 'مرخصی روزانه', 'مرخصی ساعتی']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => leaveType = val!,
                decoration: const InputDecoration(labelText: 'نوع مرخصی', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () {
                  setState(() {
                    _dayLogs[dateKey] = {
                      'overtime': double.tryParse(overtimeController.text) ?? 0,
                      'leaveType': leaveType,
                    };
                  });
                  Navigator.pop(context);
                },
                child: const Text('ثبت و ذخیره'),
              )
            ],
          ),
        );
      },
    );
  }
}

// ------------------- صفحه نمودار و خروجی عکس -------------------
class AnalyticsScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> logs;
  final ScreenshotController screenshotController = ScreenshotController();

  AnalyticsScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خلاصه کارکرد و مقایسه'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              Uint8List? imageBytes = await screenshotController.capture();
              if (imageBytes != null) {
                await ImageGallerySaver.saveImage(imageBytes, name: "work_report");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تصویر گزارش در گالری ذخیره شد')),
                  );
                }
              }
            },
          )
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              const Text('مقایسه اضافه‌کاری ماه‌های اخیر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: [
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: Colors.indigo)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 18, color: Colors.indigo)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 8, color: Colors.indigo)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 25, color: Colors.indigo)]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.timer, color: Colors.indigo),
                  title: Text('کل اضافه کار این ماه'),
                  trailing: Text('۲۵ ساعت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.beach_access, color: Colors.orange),
                  title: Text('کل مرخصی روزانه'),
                  trailing: Text('۲ روز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
