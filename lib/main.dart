import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const ShiftPlannerApp());
}

class ShiftPlannerApp extends StatelessWidget {
  const ShiftPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift Planner Pro',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        fontFamily: 'Tahoma',
      ),
      home: const OnboardingOrMainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OnboardingOrMainScreen extends StatefulWidget {
  const OnboardingOrMainScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingOrMainScreen> createState() => _OnboardingOrMainScreenState();
}

class _OnboardingOrMainScreenState extends State<OnboardingOrMainScreen> {
  bool _isLoading = true;
  bool _isConfigured = false;

  String _language = 'fa';
  String _workType = ''; 
  String _shiftPattern = ''; 
  String _currentWeekShift = ''; 

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? '';
      _workType = prefs.getString('workType') ?? '';
      _shiftPattern = prefs.getString('shiftPattern') ?? '';
      _currentWeekShift = prefs.getString('currentWeekShift') ?? '';
      _isConfigured = _language.isNotEmpty && _workType.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    await prefs.setString('workType', _workType);
    await prefs.setString('shiftPattern', _shiftPattern);
    await prefs.setString('currentWeekShift', _currentWeekShift);
    setState(() {
      _isConfigured = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isConfigured) {
      return SetupWizardScreen(
        onComplete: (lang, workType, pattern, currentWeek) {
          setState(() {
            _language = lang;
            _workType = workType;
            _shiftPattern = pattern;
            _currentWeekShift = currentWeek;
          });
          _saveSettings();
        },
      );
    }

    return MainDashboardScreen(
      language: _language,
      workType: _workType,
      currentWeekShift: _currentWeekShift,
      onResetSettings: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        setState(() {
          _isConfigured = false;
        });
      },
    );
  }
}

class SetupWizardScreen extends StatefulWidget {
  final Function(String lang, String workType, String pattern, String currentWeek) onComplete;

  const SetupWizardScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 1;
  String _selectedLang = 'fa';
  String _selectedWorkType = 'shift'; 
  String _selectedPattern = 'one_week_rotate';
  String _selectedCurrentWeek = 'day'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _step == 1 ? 'لطفاً زبان خود را انتخاب کنید' :
                      _step == 2 ? 'نوع شیفت کاری شما چگونه است؟' :
                      _step == 3 ? 'چرخش شیفت شما چطور است؟' : 'این هفته چطور هستید؟',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildStepContent(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_step > 1)
                          OutlinedButton(
                            onPressed: () => setState(() => _step--),
                            child: const Text('مرحله قبل'),
                          )
                        else
                          const SizedBox(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
                          onPressed: () {
                            if (_step < 4) {
                              setState(() => _step++);
                            } else {
                              widget.onComplete(_selectedLang, _selectedWorkType, _selectedPattern, _selectedCurrentWeek);
                            }
                          },
                          child: Text(_step == 4 ? 'ورود به برنامه' : 'مرحله بعد', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return Column(
          children: [
            _radioOption('فارسی 🇮🇷', 'fa', _selectedLang, (val) => setState(() => _selectedLang = val!)),
            _radioOption('English 🇬🇧', 'en', _selectedLang, (val) => setState(() => _selectedLang = val!)),
            _radioOption('Deutsch 🇩🇪', 'de', _selectedLang, (val) => setState(() => _selectedLang = val!)),
          ],
        );
      case 2:
        return Column(
          children: [
            _radioOption('شیفتی هستم', 'shift', _selectedWorkType, (val) => setState(() => _selectedWorkType = val!)),
            _radioOption('شیفت ثابت دارم', 'fixed', _selectedWorkType, (val) => setState(() => _selectedWorkType = val!)),
          ],
        );
      case 3:
        return Column(
          children: [
            _radioOption('یک هفته روزکار / یک هفته عصرکار', 'one_week_rotate', _selectedPattern, (val) => setState(() => _selectedPattern = val!)),
            _radioOption('سایر الگوها / چرخشی دیگر', 'other', _selectedPattern, (val) => setState(() => _selectedPattern = val!)),
          ],
        );
      case 4:
        return Column(
          children: [
            _radioOption('این هفته روزکارم ☀️', 'day', _selectedCurrentWeek, (val) => setState(() => _selectedCurrentWeek = val!)),
            _radioOption('این هفته عصرکارم 🌙', 'evening', _selectedCurrentWeek, (val) => setState(() => _selectedCurrentWeek = val!)),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _radioOption(String title, String value, String groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  final String language;
  final String workType;
  final String currentWeekShift;
  final VoidCallback onResetSettings;

  const MainDashboardScreen({
    Key? key,
    required this.language,
    required this.workType,
    required this.currentWeekShift,
    required this.onResetSettings,
  }) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Map<String, Map<String, dynamic>> _monthData = {};
  int _selectedDay = Jalali.now().day;

  final Map<String, Map<String, String>> _strings = {
    'fa': {
      'title': 'برنامه جامع شیفت و مرخصی',
      'overtime': 'اضافه کاری کل',
      'leave': 'مرخصی کل',
      'selectDay': 'مدیریت روز انتخاب شده',
      'dayShift': 'روزکار',
      'eveningShift': 'عصرکار',
      'nightShift': 'شبکار',
      'hourlyLeave': 'مرخصی ساعتی',
      'dailyLeave': 'مرخصی روزانه',
      'overtimeBtn': 'اضافه کاری',
      'noteBtn': 'یادداشت',
      'saveChart': 'ذخیره عکس نمودار در گالری',
      'successSave': 'عکس نمودار با موفقیت در گالری ذخیره شد.',
      'errorSave': 'خطا در ذخیره تصویر.',
      'chartTitle': 'نمودار آمار شیفت‌های ماه جاری',
      'reset': 'تنظیمات مجدد',
      'noteHint': 'یادداشت این روز را وارد کنید...',
      'hoursUnit': 'ساعت',
    },
    'en': {
      'title': 'Shift & Leave Manager Pro',
      'overtime': 'Total Overtime',
      'leave': 'Total Leave',
      'selectDay': 'Manage Selected Day',
      'dayShift': 'Day Shift',
      'eveningShift': 'Evening Shift',
      'nightShift': 'Night Shift',
      'hourlyLeave': 'Hourly Leave',
      'dailyLeave': 'Daily Leave',
      'overtimeBtn': 'Overtime',
      'noteBtn': 'Note',
      'saveChart': 'Save Chart to Gallery',
      'successSave': 'Chart successfully saved to gallery.',
      'errorSave': 'Error saving image.',
      'chartTitle': 'Current Month Shift Analytics',
      'reset': 'Reset Settings',
      'noteHint': 'Enter note for this day...',
      'hoursUnit': 'hrs',
    },
    'de': {
      'title': 'Schicht- & Urlaubsplaner Pro',
      'overtime': 'Gesamt Überstunden',
      'leave': 'Gesamt Urlaub',
      'selectDay': 'Ausgewählten Tag verwalten',
      'dayShift': 'Tagschicht',
      'eveningShift': 'Abendschicht',
      'nightShift': 'Nachtschicht',
      'hourlyLeave': 'Stundenurlaub',
      'dailyLeave': 'Tagesurlaub',
      'overtimeBtn': 'Überstunden',
      'noteBtn': 'Notiz',
      'saveChart': 'Diagramm in Galerie speichern',
      'successSave': 'Diagramm erfolgreich gespeichert.',
      'errorSave': 'Fehler beim Speichern.',
      'chartTitle': 'Monatliche Schichtstatistik',
      'reset': 'Einstellungen zurücksetzen',
      'noteHint': 'Notiz eingeben...',
      'hoursUnit': 'Std',
    },
  };

  String t(String key) => _strings[widget.language]?[key] ?? _strings['fa']![key]!;

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  String _getDayKey(int day) {
    Jalali now = Jalali.now();
    return "${now.year}-${now.month}-$day";
  }

  Future<void> _loadMonthData() async {
    final prefs = await SharedPreferences.getInstance();
    String? dataString = prefs.getString('month_data_storage');
    if (dataString != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(dataString);
        setState(() {
          _monthData = decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
        });
      } catch (_) {}
    }
  }

  Future<void> _saveMonthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('month_data_storage', jsonEncode(_monthData));
  }

  void _updateDayData(int day, String key, dynamic value) {
    setState(() {
      String dKey = _getDayKey(day);
      if (!_monthData.containsKey(dKey)) {
        _monthData[dKey] = {};
      }
      _monthData[dKey]![key] = value;
    });
    _saveMonthData();
  }

  dynamic _getDayData(int day, String key, {dynamic defaultValue}) {
    String dKey = _getDayKey(day);
    return _monthData[dKey]?[key] ?? defaultValue;
  }

  double _getTotalForMonth(String key) {
    Jalali today = Jalali.now();
    int daysInMonth = today.month <= 6 ? 31 : (today.month <= 11 ? 30 : (Jalali(today.year, 1, 1).isLeapYear() ? 30 : 29));
    double total = 0.0;
    for (int i = 1; i <= daysInMonth; i++) {
      var val = _getDayData(i, key, defaultValue: 0.0);
      if (val is num) {
        total += val.toDouble();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    Jalali today = Jalali.now();
    int daysInMonth = today.month <= 6 ? 31 : (today.month <= 11 ? 30 : (Jalali(today.year, 1, 1).isLeapYear() ? 30 : 29));
    Jalali firstDayOfMonth = Jalali(today.year, today.month, 1);
    int startWeekday = firstDayOfMonth.weekDay; // 1=شنبه تا 7=جمعه

    double totalOvertime = _getTotalForMonth('overtime');
    double totalLeave = _getTotalForMonth('hourly_leave');

    return Scaffold(
      appBar: AppBar(
        title: Text(t('title'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            tooltip: t('reset'),
            onPressed: widget.onResetSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _statCard(t('overtime'), '$totalOvertime ${t('hoursUnit')}', Icons.timer, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(t('leave'), '$totalLeave ${t('hoursUnit')}', Icons.beach_access, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${today.formatter.yyyy}/${today.formatter.mm}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
                        Text('امروز: ${today.day}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('شنبه', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Text('یکشنبه', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Text('دوشنبه', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Text('سه‌شنبه', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Text('چهارشنبه', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Text('پنج‌شنبه', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Text('جمعه', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: daysInMonth + (startWeekday - 1),
                      itemBuilder: (context, index) {
                        if (index < startWeekday - 1) {
                          return const SizedBox.shrink();
                        }
                        int dayNum = index - (startWeekday - 2);
                        bool isSelected = _selectedDay == dayNum;
                        bool isFriday = (index % 7) == 6;

                        String shiftCode = _getDayData(dayNum, 'shift', defaultValue: widget.currentWeekShift);
                        bool isDailyLeave = _getDayData(dayNum, 'daily_leave', defaultValue: false);
                        double hourlyLeaveVal = _getDayData(dayNum, 'hourly_leave', defaultValue: 0.0);
                        double overtimeVal = _getDayData(dayNum, 'overtime', defaultValue: 0.0);
                        String noteVal = _getDayData(dayNum, 'note', defaultValue: '');

                        Color cellColor = isFriday ? Colors.red.shade50.withOpacity(0.5) : Colors.white;
                        String shiftLabel = '';

                        if (isDailyLeave) {
                          cellColor = Colors.deepOrange.shade100;
                          shiftLabel = 'مرخصی روزانه';
                        } else {
                          if (shiftCode == 'day') {
                            shiftLabel = 'روزکار';
                            cellColor = isFriday ? Colors.red.shade50 : Colors.amber.shade100;
                          } else if (shiftCode == 'evening') {
                            shiftLabel = 'عصرکار';
                            cellColor = isFriday ? Colors.red.shade50 : Colors.blue.shade100;
                          } else if (shiftCode == 'night') {
                            shiftLabel = 'شبکار';
                            cellColor = isFriday ? Colors.red.shade50 : Colors.purple.shade100;
                          }
                        }

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = dayNum),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF3F51B5) : cellColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? Colors.indigo.shade900 : (isFriday ? Colors.red.shade200 : Colors.grey.shade300),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : (isFriday ? Colors.red.shade700 : Colors.black87),
                                  ),
                                ),
                                Column(
                                  children: [
                                    if (shiftLabel.isNotEmpty)
                                      Text(
                                        shiftLabel,
                                        style: TextStyle(fontSize: 8, color: isSelected ? Colors.white70 : Colors.grey.shade800),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (overtimeVal > 0)
                                      Text(
                                        '+${overtimeVal} ک',
                                        style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: isSelected ? Colors.greenAccent : Colors.green.shade800),
                                      ),
                                    if (hourlyLeaveVal > 0)
                                      Text(
                                        'م.${hourlyLeaveVal}س',
                                        style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: isSelected ? Colors.orangeAccent : Colors.orange.shade800),
                                      ),
                                    if (noteVal.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 1),
                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.pink.shade300 : Colors.pink.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'یادداشت',
                                          style: TextStyle(fontSize: 6, color: isSelected ? Colors.white : Colors.pink.shade900),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('selectDay') + ' (روز $_selectedDay):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _shiftButton(t('dayShift'), Colors.amber, 'day'),
                        _shiftButton(t('eveningShift'), Colors.blue, 'evening'),
                        _shiftButton(t('nightShift'), Colors.purple, 'night'),
                      ],
                    ),
                    const Divider(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _toggleDailyLeave(_selectedDay),
                          icon: const Icon(Icons.free_breakfast, size: 16),
                          label: Text(_getDayData(_selectedDay, 'daily_leave', defaultValue: false) ? 'لغو مرخصی' : t('dailyLeave'), style: const TextStyle(fontSize: 11)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _showHourlyLeaveDialog(_selectedDay),
                          icon: const Icon(Icons.hourglass_bottom, size: 16),
                          label: Text(t('hourlyLeave'), style: const TextStyle(fontSize: 11)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _showOvertimeDialog(_selectedDay),
                          icon: const Icon(Icons.add_task, size: 16),
                          label: Text(t('overtimeBtn'), style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: TextEditingController(text: _getDayData(_selectedDay, 'note', defaultValue: ''))
                        ..selection = TextSelection.fromPosition(TextPosition(offset: (_getDayData(_selectedDay, 'note', defaultValue: '') as String).length)),
                      decoration: InputDecoration(
                        labelText: t('noteHint'),
                        labelStyle: TextStyle(color: Colors.pink.shade700, fontSize: 12),
                        prefixIcon: Icon(Icons.note_alt, color: Colors.pink.shade400, size: 18),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink.shade400, width: 2), borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink.shade200), borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) => _updateDayData(_selectedDay, 'note', val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, spreadRadius: 2)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('chartTitle'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 20,
                          barGroups: [
                            BarChartGroupData(x: 0, rod: BarChartRodData(toY: _countShiftType('day').toDouble(), color: Colors.amber, width: 18, borderRadius: BorderRadius.circular(6))),
                            BarChartGroupData(x: 1, rod: BarChartRodData(toY: _countShiftType('evening').toDouble(), color: Colors.blue, width: 18, borderRadius: BorderRadius.circular(6))),
                            BarChartGroupData(x: 2, rod: BarChartRodData(toY: _countShiftType('night').toDouble(), color: Colors.purple, width: 18, borderRadius: BorderRadius.circular(6))),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0: return const Text('روزکار', style: TextStyle(fontSize: 11));
                                    case 1: return const Text('عصرکار', style: TextStyle(fontSize: 11));
                                    case 2: return const Text('شبکار', style: TextStyle(fontSize: 11));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _captureAndSaveChart,
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(t('saveChart'), style: const TextStyle(color: Colors.white, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countShiftType(String type) {
    Jalali today = Jalali.now();
    int daysInMonth = today.month <= 6 ? 31 : (today.month <= 11 ? 30 : (Jalali(today.year, 1, 1).isLeapYear() ? 30 : 29));
    int count = 0;
    for (int i = 1; i <= daysInMonth; i++) {
      String shift = _getDayData(i, 'shift', defaultValue: widget.currentWeekShift);
      bool isDailyLeave = _getDayData(i, 'daily_leave', defaultValue: false);
      if (!isDailyLeave && shift == type) {
        count++;
      }
    }
    return count;
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftButton(String label, Color color, String shiftCode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        _updateDayData(_selectedDay, 'shift', shiftCode);
        _updateDayData(_selectedDay, 'daily_leave', false);
      },
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _toggleDailyLeave(int day) {
    bool current = _getDayData(day, 'daily_leave', defaultValue: false);
    _updateDayData(day, 'daily_leave', !current);
  }

  void _showHourlyLeaveDialog(int day) {
    double currentVal = _getDayData(day, 'hourly_leave', defaultValue: 0.0);
    TextEditingController controller = TextEditingController(text: currentVal > 0 ? currentVal.toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مرخصی ساعتی روز $day'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'تعداد ساعات مرخصی'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              double val = double.tryParse(controller.text) ?? 0.0;
              _updateDayData(day, 'hourly_leave', val);
              Navigator.pop(context);
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  void _showOvertimeDialog(int day) {
    double currentVal = _getDayData(day, 'overtime', defaultValue: 0.0);
    TextEditingController controller = TextEditingController(text: currentVal > 0 ? currentVal.toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اضافه کاری روز $day'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'تعداد ساعات اضافه کاری'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              double val = double.tryParse(controller.text) ?? 0.0;
              _updateDayData(day, 'overtime', val);
              Navigator.pop(context);
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndSaveChart() async {
    try {
      final imageUint8List = await _screenshotController.capture();
      if (imageUint8List != null) {
        final result = await ImageGallerySaverPlus.saveImage(
          imageUint8List,
          quality: 100,
          name: "Chart_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('successSave')), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('errorSave')), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
