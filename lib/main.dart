import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShiftTrackerApp());
}

// مدیریت متن‌ها و ترجمه‌های برنامه (فارسی، انگلیسی، آلمانی)
class AppStrings {
  final String langCode;
  AppStrings(this.langCode);

  static const Map<String, Map<String, String>> _translations = {
    'fa': {
      'app_title': 'مدیریت شیفت و کارکرد',
      'tab_calendar': 'تقویم و شیفت‌ها',
      'tab_reports': 'گزارش و نمودار',
      'overtime': 'اضافه‌کار',
      'daily_leave': 'مرخصی روزانه',
      'hourly_leave': 'مرخصی ساعتی',
      'current_shift': 'شیفت:',
      'change_shift': 'تغییر شیفت',
      'settings': 'تنظیمات',
      'language': 'زبان برنامه',
      'select_language': 'زبان مورد نظر خود را انتخاب کنید',
      'save_shift': 'تایید و ذخیره شیفت',
      'day_settings': 'تنظیمات روز',
      'hourly_leave_hours': 'تعداد ساعت مرخصی',
      'daily_note': 'یادداشت روزانه',
      'save_changes': 'ثبت تغییرات',
      'save_chart_image': 'ذخیره نمودار به صورت عکس در گالری',
      'chart_saved_msg': 'تصویر نمودار با موفقیت ذخیره شد!',
      'select_shift_type': 'شیفت کاری خود را انتخاب کنید:',
      'how_is_this_week': 'این هفته چطور هستید؟',
    },
    'en': {
      'app_title': 'Shift & Work Tracker',
      'tab_calendar': 'Calendar & Shifts',
      'tab_reports': 'Reports & Chart',
      'overtime': 'Overtime',
      'daily_leave': 'Daily Leave',
      'hourly_leave': 'Hourly Leave',
      'current_shift': 'Shift:',
      'change_shift': 'Change Shift',
      'settings': 'Settings',
      'language': 'App Language',
      'select_language': 'Select your preferred language',
      'save_shift': 'Save Shift',
      'day_settings': 'Day Settings',
      'hourly_leave_hours': 'Leave Hours',
      'daily_note': 'Daily Note',
      'save_changes': 'Save Changes',
      'save_chart_image': 'Save Chart as Image to Gallery',
      'chart_saved_msg': 'Chart saved to gallery successfully!',
      'select_shift_type': 'Select your shift type:',
      'how_is_this_week': 'How is your shift this week?',
    },
    'de': {
      'app_title': 'Schicht- und Arbeitsplaner',
      'tab_calendar': 'Kalender & Schichten',
      'tab_reports': 'Berichte & Diagramm',
      'overtime': 'Überstunden',
      'daily_leave': 'Tagesurlaub',
      'hourly_leave': 'Stundenurlaub',
      'current_shift': 'Schicht:',
      'change_shift': 'Schicht ändern',
      'settings': 'Einstellungen',
      'language': 'App-Sprache',
      'select_language': 'Wählen Sie Ihre Sprache',
      'save_shift': 'Schicht speichern',
      'day_settings': 'Tages-Einstellungen',
      'hourly_leave_hours': 'Urlaubsstunden',
      'daily_note': 'Tagesnotiz',
      'save_changes': 'Änderungen speichern',
      'save_chart_image': 'Diagramm als Bild in Galerie speichern',
      'chart_saved_msg': 'Diagramm erfolgreich in Galerie gespeichert!',
      'select_shift_type': 'Wählen Sie Ihren Schichttyp:',
      'how_is_this_week': 'Wie ist Ihre Schicht diese Woche?',
    }
  };

  String get(String key) {
    return _translations[langCode]?[key] ?? _translations['fa']?[key] ?? key;
  }
}

class ShiftTrackerApp extends StatefulWidget {
  const ShiftTrackerApp({Key? key}) : super(key: key);

  @override
  State<ShiftTrackerApp> createState() => _ShiftTrackerAppSt();

  static void setLocale(BuildContext context, String newLang) {
    _ShiftTrackerAppSt? state = context.findAncestorStateOfType<_ShiftTrackerAppSt>();
    state?.changeLanguage(newLang);
  }
}

class _ShiftTrackerAppSt extends State<ShiftTrackerApp> {
  String _currentLang = '';

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLang = prefs.getString('app_language') ?? '';
    });
  }

  void changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    setState(() {
      _currentLang = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLang.isEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LanguageSelectionScreen(onSelected: (lang) {
          changeLanguage(lang);
        }),
      );
    }

    return MaterialApp(
      title: 'Shift Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: _currentLang == 'en' ? TextDirection.ltr : TextDirection.rtl,
          child: child!,
        );
      },
      home: MainContainerScreen(langCode: _currentLang),
    );
  }
}

class LanguageSelectionScreen extends StatelessWidget {
  final Function(String) onSelected;
  const LanguageSelectionScreen({Key? key, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text('لطفاً زبان برنامه را انتخاب کنید / Choose your language / Sprache wählen',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _buildLangButton(context, 'فارسی (Persian)', 'fa'),
              const SizedBox(height: 12),
              _buildLangButton(context, 'English', 'en'),
              const SizedBox(height: 12),
              _buildLangButton(context, 'Deutsch (German)', 'de'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(BuildContext context, String title, String code) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => onSelected(code),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class MainContainerScreen extends StatefulWidget {
  final String langCode;
  const MainContainerScreen({Key? key, required this.langCode}) : super(key: key);

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;
  Map<String, Map<String, dynamic>> monthlyData = {};
  String mainShiftType = '';
  String subShiftDetail = '';
  
  int currentMonthIndex = Jalali.now().month - 1;
  int currentYear = Jalali.now().year;

  final List<String> shamsiMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('saved_monthly_tracker_data');
    String? storedMainShift = prefs.getString('main_shift_type');
    String? storedSubShift = prefs.getString('sub_shift_detail');

    setState(() {
      if (storedData != null) {
        Map<String, dynamic> decoded = jsonDecode(storedData);
        monthlyData = decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      }
      mainShiftType = storedMainShift ?? '';
      subShiftDetail = storedSubShift ?? '';
    });

    if (mainShiftType.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showShiftSetupWizard();
      });
    }
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_monthly_tracker_data', jsonEncode(monthlyData));
    await prefs.setString('main_shift_type', mainShiftType);
    await prefs.setString('sub_shift_detail', subShiftDetail);
  }

  void updateMonthlyData(Map<String, Map<String, dynamic>> newData) {
    setState(() {
      monthlyData = newData;
    });
    _saveAllData(); 
  }

  void changeMonth(int year, int monthIndex) {
    setState(() {
      currentYear = year;
      currentMonthIndex = monthIndex;
    });
  }

  void _showShiftSetupWizard() {
    AppStrings strings = AppStrings(widget.langCode);
    String tempMain = mainShiftType.isEmpty ? 'همیشه صبح' : mainShiftType;
    String tempSub = subShiftDetail;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(strings.get('settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple), textAlign: TextAlign.center),
                      const SizedBox(height: 15),
                      Text(strings.get('select_shift_type'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: tempMain.isNotEmpty ? tempMain : 'همیشه صبح',
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: [
                          '12-24', 
                          '24-48', 
                          'همیشه صبح', 
                          'همیشه عصر', 
                          'همیشه شب', 
                          'یک هفته روز یک هفته عصر',
                          'شیفت دوروز',
                          'شیفت سه روز',
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            tempMain = val!;
                            if (tempMain != 'یک هفته روز یک هفته عصر') tempSub = '';
                          });
                        },
                      ),
                      if (tempMain == 'یک هفته روز یک هفته عصر') ...[
                        const SizedBox(height: 15),
                        Text(strings.get('how_is_this_week'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: tempSub.isNotEmpty ? tempSub : 'این هفته صبح‌کار',
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          items: ['این هفته صبح‌کار', 'این هفته عصر‌کار']
                              .map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                          onChanged: (val) => setModalState(() => tempSub = val!),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          setState(() {
                            mainShiftType = tempMain;
                            subShiftDetail = tempSub;
                          });
                          _saveAllData();
                          Navigator.pop(context);
                        },
                        child: Text(strings.get('save_shift'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AppStrings strings = AppStrings(widget.langCode);

    final List<Widget> screens = [
      ShamsiCalendarScreen(
        monthlyData: monthlyData,
        currentYear: currentYear,
        currentMonthIndex: currentMonthIndex,
        mainShiftType: mainShiftType,
        subShiftDetail: subShiftDetail,
        langCode: widget.langCode,
        onDataChanged: updateMonthlyData,
        onMonthChanged: changeMonth,
        onOpenShiftSetup: _showShiftSetupWizard,
      ),
      ReportsChartScreen(
        monthlyData: monthlyData,
        currentYear: currentYear,
        currentMonthIndex: currentMonthIndex,
        shamsiMonths: shamsiMonths,
        langCode: widget.langCode,
      ),
      SettingsScreen(
        currentLang: widget.langCode,
        onOpenShiftSetup: _showShiftSetupWizard,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month), label: strings.get('tab_calendar')),
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: strings.get('tab_reports')),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: strings.get('settings')),
        ],
      ),
    );
  }
}

class ShamsiCalendarScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> monthlyData;
  final int currentYear;
  final int currentMonthIndex;
  final String mainShiftType;
  final String subShiftDetail;
  final String langCode;
  final Function(Map<String, Map<String, dynamic>>) onDataChanged;
  final Function(int, int) onMonthChanged;
  final VoidCallback onOpenShiftSetup;

  const ShamsiCalendarScreen({
    Key? key,
    required this.monthlyData,
    required this.currentYear,
    required this.currentMonthIndex,
    required this.mainShiftType,
    required this.subShiftDetail,
    required this.langCode,
    required this.onDataChanged,
    required this.onMonthChanged,
    required this.onOpenShiftSetup,
  }) : super(key: key);

  final List<String> shamsiMonths = const [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  final List<String> weekDays = const [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'
  ];

  String get _currentMonthKey => '$currentYear-$currentMonthIndex';

  double get currentMonthOvertime {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    double total = 0.0;
    monthMap.forEach((day, data) {
      if (data is Map && data['overtime'] != null) {
        total += double.tryParse(data['overtime'].toString()) ?? 0.0;
      }
    });
    return total;
  }

  int get currentMonthLeaveDays {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['status'] == 'leave_daily') {
        total += 1;
      }
    });
    return total;
  }

  double get currentMonthLeaveHours {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    double total = 0.0;
    monthMap.forEach((day, data) {
      if (data is Map && data['leave_hours'] != null) {
        total += double.tryParse(data['leave_hours'].toString()) ?? 0.0;
      }
    });
    return total;
  }

  void _previousMonth() {
    int y = currentYear;
    int m = currentMonthIndex;
    if (m > 0) m--; else { m = 11; y--; }
    onMonthChanged(y, m);
  }

  void _nextMonth() {
    int y = currentYear;
    int m = currentMonthIndex;
    if (m < 11) m++; else { m = 0; y++; }
    onMonthChanged(y, m);
  }

  bool _isToday(int dayNum) {
    Jalali jNow = Jalali.now();
    return currentYear == jNow.year && 
           currentMonthIndex == (jNow.month - 1) && 
           dayNum == jNow.day;
  }

  String _getDefaultDayShiftLabel(int dayNum) {
    if (mainShiftType == 'همیشه صبح') return 'روزکار';
    if (mainShiftType == 'همیشه عصر') return 'عصرکار';
    if (mainShiftType == 'همیشه شب') return 'شب‌کار';
    if (mainShiftType == '12-24') return dayNum % 2 == 1 ? 'شیفت 12' : 'استراحت';
    if (mainShiftType == '24-48') return dayNum % 3 == 1 ? 'شیفت 24' : 'استراحت';
    
    if (mainShiftType == 'شیفت دوروز') {
      int cycle = (dayNum - 1) % 8;
      if (cycle < 2) return 'روزکار';
      if (cycle < 4) return 'عصرکار';
      if (cycle < 6) return 'شب‌کار';
      return 'استراحت';
    }

    if (mainShiftType == 'شیفت سه روز') {
      int cycle = (dayNum - 1) % 12;
      if (cycle < 3) return 'روزکار';
      if (cycle < 6) return 'عصرکار';
      if (cycle < 9) return 'شب‌کار';
      return 'استراحت';
    }

    if (mainShiftType == 'یک هفته روز یک هفته عصر') {
      bool isFirstHalfWeek = ((dayNum - 1) ~/ 7) % 2 == 0;
      if (subShiftDetail == 'این هفته صبح‌کار') {
        return isFirstHalfWeek ? 'روزکار' : 'عصرکار';
      } else {
        return isFirstHalfWeek ? 'عصرکار' : 'روزکار';
      }
    }
    return 'عادی';
  }

  @override
  Widget build(BuildContext context) {
    AppStrings strings = AppStrings(langCode);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(strings.get('overtime'), '${currentMonthOvertime == currentMonthOvertime.toInt() ? currentMonthOvertime.toInt() : currentMonthOvertime.toStringAsFixed(1)} ساعت', Icons.timer),
              Container(height: 35, width: 1, color: Colors.white30),
              _buildHeaderStat(strings.get('daily_leave'), '$currentMonthLeaveDays روز', Icons.event_busy),
              Container(height: 35, width: 1, color: Colors.white30),
              _buildHeaderStat(strings.get('hourly_leave'), '${currentMonthLeaveHours == currentMonthLeaveHours.toInt() ? currentMonthLeaveHours.toInt() : currentMonthLeaveHours.toStringAsFixed(1)} ساعت', Icons.hourglass_bottom),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${strings.get('current_shift')} $mainShiftType ${subShiftDetail.isNotEmpty ? "($subShiftDetail)" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onOpenShiftSetup,
                icon: const Icon(Icons.settings, size: 14),
                label: Text(strings.get('change_shift'), style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _nextMonth, icon: const Icon(Icons.arrow_forward_ios, size: 16), color: Colors.deepPurple),
              Text('${shamsiMonths[currentMonthIndex]} $currentYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              IconButton(onPressed: _previousMonth, icon: const Icon(Icons.arrow_back_ios, size: 16), color: Colors.deepPurple),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              bool isFri = day == 'جمعه';
              return Expanded(
                child: Center(
                  child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isFri ? Colors.red.shade700 : Colors.grey.shade700)),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              int dayNum = index + 1;
              bool isFriday = (index % 7 == 6);
              bool isTodayFlag = _isToday(dayNum);
              
              final monthMap = monthlyData[_currentMonthKey] ?? {};
              final dayData = monthMap[dayNum.toString()] as Map<String, dynamic>?;

              String? status = dayData?['status'];
              String? otVal = dayData?['overtime'];
              String? lhVal = dayData?['leave_hours'];
              String? note = dayData?['note'];
              
              String defaultShiftLabel = _getDefaultDayShiftLabel(dayNum);

              Color bgColor = isFriday ? Colors.red.shade50 : Colors.white;
              Color borderColor = isFriday ? Colors.red.shade200 : Colors.grey.shade300;
              Color textColor = isFriday ? Colors.red.shade800 : Colors.black87;

              if (isTodayFlag) {
                borderColor = Colors.amber.shade800;
                bgColor = Colors.amber.shade50;
              }
              if (status == 'overtime') {
                bgColor = Colors.purple.shade50;
                borderColor = Colors.purple.shade300;
              } else if (status == 'leave_daily') {
                bgColor = Colors.orange.shade100;
                borderColor = Colors.orange.shade400;
              } else if (status == 'leave_hourly') {
                bgColor = Colors.teal.shade50;
                borderColor = Colors.teal.shade300;
              }

              return InkWell(
                onTap: () => _showDaySettingsModal(context, dayNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: isTodayFlag ? 2 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$dayNum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isTodayFlag ? Colors.amber.shade900 : textColor)),
                          if (note != null && note.trim().isNotEmpty) ...[
                            const SizedBox(width: 2),
                            const Icon(Icons.note, size: 10, color: Colors.blueAccent),
                          ]
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(defaultShiftLabel, style: TextStyle(fontSize: 8, color: Colors.grey.shade800, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (otVal != null && otVal.isNotEmpty && otVal != '0')
                        Text('+${otVal}ک', style: TextStyle(fontSize: 8, color: Colors.purple.shade800, fontWeight: FontWeight.bold)),
                      if (status == 'leave_daily')
                        const Text('م.روز', style: TextStyle(fontSize: 7, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                      if (lhVal != null && lhVal.isNotEmpty && lhVal != '0')
                        Text('${lhVal}س.م', style: TextStyle(fontSize: 8, color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String title, String val, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 8)),
      ],
    );
  }

  void _showDaySettingsModal(BuildContext context, int dayNum) {
    AppStrings strings = AppStrings(langCode);
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    final dayData = monthMap[dayNum.toString()] as Map<String, dynamic>?;

    final TextEditingController otController = TextEditingController(text: dayData?['overtime'] ?? '');
    final TextEditingController leaveHourController = TextEditingController(text: dayData?['leave_hours'] ?? '');
    final TextEditingController noteController = TextEditingController(text: dayData?['note'] ?? '');
    
    String leaveType = dayData?['status'] ?? 'بدون مرخصی';
    if (leaveType == 'leave_daily') {
      leaveType = 'مرخصی روزانه';
    } else if (leaveType == 'leave_hourly') {
      leaveType = 'مرخصی ساعتی';
    } else {
      leaveType = 'بدون مرخصی';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${strings.get('day_settings')} $dayNum ${shamsiMonths[currentMonthIndex]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 15),
                        TextField(
                          controller: otController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: strings.get('overtime'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: leaveType,
                          decoration: InputDecoration(labelText: strings.get('daily_leave'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          items: ['بدون مرخصی', 'مرخصی روزانه', 'مرخصی ساعتی'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setModalState(() => leaveType = val!),
                        ),
                        if (leaveType == 'مرخصی ساعتی') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: leaveHourController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: strings.get('hourly_leave_hours'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(labelText: strings.get('daily_note'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                          onPressed: () {
                            String ot = otController.text.trim();
                            String lh = leaveHourController.text.trim();
                            String note = noteController.text.trim();

                            Map<String, Map<String, dynamic>> updatedData = Map.from(monthlyData);
                            if (updatedData[_currentMonthKey] == null) {
                              updatedData[_currentMonthKey] = {};
                            }

                            String finalStatus = 'normal';
                            if (leaveType == 'مرخصی روزانه') finalStatus = 'leave_daily';
                            else if (leaveType == 'مرخصی ساعتی') finalStatus = 'leave_hourly';
                            else if (ot.isNotEmpty && ot != '0') finalStatus = 'overtime';

                            updatedData[_currentMonthKey]![dayNum.toString()] = {
                              'status': finalStatus,
                              'overtime': ot,
                              'leave_hours': leaveType == 'مرخصی ساعتی' ? lh : '',
                              'note': note,
                            };

                            onDataChanged(updatedData);
                            Navigator.pop(context);
                          },
                          child: Text(strings.get('save_changes')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ReportsChartScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> monthlyData;
  final int currentYear;
  final int currentMonthIndex;
  final List<String> shamsiMonths;
  final String langCode;

  const ReportsChartScreen({
    Key? key,
    required this.monthlyData,
    required this.currentYear,
    required this.currentMonthIndex,
    required this.shamsiMonths,
    required this.langCode,
  }) : super(key: key);

  String get _currentMonthKey => '$currentYear-$currentMonthIndex';

  double get totalOvertime {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    double total = 0.0;
    monthMap.forEach((day, data) {
      if (data is Map && data['overtime'] != null) {
        total += double.tryParse(data['overtime'].toString()) ?? 0.0;
      }
    });
    return total;
  }

  int get totalLeaveDays {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['status'] == 'leave_daily') total += 1;
    });
    return total;
  }

  double get totalLeaveHours {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    double total = 0.0;
    monthMap.forEach((day, data) {
      if (data is Map && data['leave_hours'] != null) {
        total += double.tryParse(data['leave_hours'].toString()) ?? 0.0;
      }
    });
    return total;
  }

  void _saveChartToGallery(BuildContext context, AppStrings strings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.get('chart_saved_msg'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppStrings strings = AppStrings(langCode);
    String monthName = shamsiMonths[currentMonthIndex];

    double otVal = totalOvertime;
    double lvDaysVal = totalLeaveDays.toDouble();
    double lvHoursVal = totalLeaveHours;

    double maxBarValue = [otVal, lvDaysVal * 8, lvHoursVal].reduce((a, b) => a > b ? a : b);
    if (maxBarValue < 10) maxBarValue = 10;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$monthName $currentYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildReportCard(strings.get('overtime'), '${otVal == otVal.toInt() ? otVal.toInt() : otVal.toStringAsFixed(1)} ساعت', Colors.purple.shade50, Colors.purple.shade800, Icons.timer)),
              const SizedBox(width: 8),
              Expanded(child: _buildReportCard(strings.get('daily_leave'), '$totalLeaveDays روز', Colors.orange.shade50, Colors.orange.shade800, Icons.event_busy)),
              const SizedBox(width: 8),
              Expanded(child: _buildReportCard(strings.get('hourly_leave'), '${lvHoursVal == lvHoursVal.toInt() ? lvHoursVal.toInt() : lvHoursVal.toStringAsFixed(1)} ساعت', Colors.teal.shade50, Colors.teal.shade800, Icons.hourglass_bottom)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(strings.get('overtime'), otVal, maxBarValue, Colors.purple, isHours: true),
                        _buildBar(strings.get('daily_leave'), lvDaysVal * 8, maxBarValue, Colors.orange, subLabel: '($totalLeaveDays روز)', isHours: false),
                        _buildBar(strings.get('hourly_leave'), lvHoursVal, maxBarValue, Colors.teal, isHours: true),
                      ],
                    ),
                  ),
                  const Divider(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    onPressed: () => _saveChartToGallery(context, strings),
                    icon: const Icon(Icons.download, size: 16),
                    label: Text(strings.get('save_chart_image')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: textColor.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, double maxVal, Color color, {String? subLabel, required bool isHours}) {
    double heightFactor = (value / maxVal).clamp(0.08, 1.0);
    String displayVal = value == value.toInt() ? '${value.toInt()}' : value.toStringAsFixed(1);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          isHours ? '$displayVal س' : displayVal, 
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)
        ),
        if (subLabel != null)
          Text(subLabel, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Container(
          width: 38,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final String currentLang;
  final VoidCallback onOpenShiftSetup;

  const SettingsScreen({Key? key, required this.currentLang, required this.onOpenShiftSetup}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppStrings strings = AppStrings(currentLang);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.get('settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 20),
          ListTile(
            title: Text(strings.get('language')),
            subtitle: Text(currentLang == 'en' ? 'English' : (currentLang == 'de' ? 'Deutsch' : 'فارسی')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(strings.get('change_shift')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: onOpenShiftSetup,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    AppStrings strings = AppStrings(currentLang);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.get('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('فارسی'),
                onTap: () {
                  ShiftTrackerApp.setLocale(context, 'fa');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English'),
                onTap: () {
                  ShiftTrackerApp.setLocale(context, 'en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Deutsch'),
                onTap: () {
                  ShiftTrackerApp.setLocale(context, 'de');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
