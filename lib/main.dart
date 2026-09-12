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
      title: 'Shift Tracker Pro',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo Primary
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981), // Emerald
          surface: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
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

// ------------------- صفحه انتخاب زبان مدرن -------------------
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 64, color: Color(0xFF818CF8)),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'خوش آمدید / Welcome',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لطفاً زبان برنامه را انتخاب کنید',
                    style: TextStyle(fontSize: 14, color: Colors.slate.shade300),
                  ),
                  const SizedBox(height: 40),
                  _buildLangBtn(context, 'فارسی (Persian)', 'fa', '🇮🇷'),
                  const SizedBox(height: 14),
                  _buildLangBtn(context, 'English', 'en', '🇬🇧'),
                  const SizedBox(height: 14),
                  _buildLangBtn(context, 'Deutsch', 'de', '🇩🇪'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangBtn(BuildContext context, String title, String code, String flag) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF334155),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () => _selectLanguage(context, code),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(flag, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}

// ------------------- صفحه اصلی با تقویم مدرن -------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Jalali _selectedMonth = Jalali.now();
  final Map<String, Map<String, dynamic>> _dayLogs = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('مدیریت شیفت و کارکرد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.insights_rounded, color: Color(0xFF6366F1)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsScreen(logs: _dayLogs)));
              },
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 12),
          _buildMonthHeader(),
          const SizedBox(height: 8),
          _buildWeekDaysHeader(),
          Expanded(child: _buildJalaliGrid()),
        ],
      ),
    );
  }

  // کارت خلاصه بالای صفحه
  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('اضافه‌کار ماه', '۲۴ ساعت', Icons.access_time_filled_rounded),
          Container(height: 36, width: 1, color: Colors.white24),
          _buildStatItem('مرخصی روزانه', '۲ روز', Icons.event_available_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => setState(() => _selectedMonth = _selectedMonth.addMonths(-1)),
          ),
          Text(
            '${_selectedMonth.formatter.mN} ${_selectedMonth.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onPressed: () => setState(() => _selectedMonth = _selectedMonth.addMonths(1)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    final days = ['ش', '۱ش', '۲ش', '۳ش', '۴ش', '۵ش', 'ج'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) => Text(d, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))).toList(),
      ),
    );
  }

  Widget _buildJalaliGrid() {
    int daysInMonth = _selectedMonth.monthLength;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        int day = index + 1;
        String dateKey = '${_selectedMonth.year}-${_selectedMonth.month}-$day';
        var log = _dayLogs[dateKey] ?? {};
        bool hasData = log.isNotEmpty;

        return GestureDetector(
          onTap: () => _showEditDialog(dateKey, day),
          child: Container(
            decoration: BoxDecoration(
              color: hasData ? const Color(0xFFEEF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasData ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
                width: hasData ? 1.5 : 1,
              ),
              boxShadow: [
                if (hasData)
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: hasData ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                if (log['overtime'] != null && log['overtime'] > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${log['overtime']}h',
                      style: const TextStyle(fontSize: 8, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                    ),
                  ),
                if (log['leaveType'] != null && log['leaveType'] != 'بدون مرخصی')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.circle, size: 6, color: Colors.amber.shade700),
                  ),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              Text('تنظیمات روز $day ${_selectedMonth.formatter.mN}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: overtimeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ساعت اضافه‌کاری',
                  prefixIcon: const Icon(Icons.add_alarm_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: leaveType,
                items: ['بدون مرخصی', 'مرخصی روزانه', 'مرخصی ساعتی']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => leaveType = val!,
                decoration: InputDecoration(
                  labelText: 'وضعیت مرخصی',
                  prefixIcon: const Icon(Icons.beach_access_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _dayLogs[dateKey] = {
                      'overtime': double.tryParse(overtimeController.text) ?? 0,
                      'leaveType': leaveType,
                    };
                  });
                  Navigator.pop(context);
                },
                child: const Text('ثبت و ذخیره تغییرات', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
    );
  }
}

// ------------------- صفحه نمودار گرافیکی پیشرفته -------------------
class AnalyticsScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> logs;
  final ScreenshotController screenshotController = ScreenshotController();

  AnalyticsScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش و مقایسه ماهانه'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              Uint8List? imageBytes = await screenshotController.capture();
              if (imageBytes != null) {
                await ImageGallerySaver.saveImage(imageBytes, name: "work_report");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('گزارش تصویری در گالری ذخیره شد')),
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
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              const Text('روند اضافه‌کاری ۴ ماه اخیر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: [
                      _buildBarGroup(1, 14, 'فروردین'),
                      _buildBarGroup(2, 22, 'اردیبهشت'),
                      _buildBarGroup(3, 10, 'خرداد'),
                      _buildBarGroup(4, 28, 'تیر'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildReportCard('مجموع اضافه‌کار', '۲۸ ساعت', Icons.timer_rounded, const Color(0xFF6366F1)),
              const SizedBox(height: 12),
              _buildReportCard('مرخصی‌های استفاده شده', '۳ روز', Icons.beach_access_rounded, const Color(0xFFF59E0B)),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 18,
          borderRadius: BorderRadius.circular(8),
        )
      ],
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
