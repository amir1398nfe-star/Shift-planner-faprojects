import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

void main() {
  runApp(const ShiftPlannerApp());
}

class ShiftPlannerApp extends StatefulWidget {
  const ShiftPlannerApp({Key? key}) : super(key: key);

  @override
  State<ShiftPlannerApp> createState() => _ShiftPlannerAppState();
}

class _ShiftPlannerAppState extends State<ShiftPlannerApp> {
  // زبان پیش‌فرض برنامه (فارسی، انگلیسی، آلمانی)
  String _currentLanguage = 'fa';

  void _changeLanguage(String lang) {
    setState(() {
      _currentLanguage = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift & Leave Planner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WorkCalendarScreen(
        language: _currentLanguage,
        onLanguageChanged: _changeLanguage,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// دیکشنری زبان‌ها (فارسی، انگلیسی، آلمانی)
class AppStrings {
  static const Map<String, Map<String, String>> translations = {
    'fa': {
      'title': 'برنامه شیفت، اضافه کاری و مرخصی',
      'dayShift': 'روزکار',
      'eveningShift': 'عصرکار',
      'nightShift': 'شبکار',
      'overtime': 'اضافه کاری:',
      'leave': 'مرخصی ساعتی:',
      'saveChart': 'ذخیره عکس نمودار در گالری',
      'successSave': 'عکس نمودار با موفقیت در گالری ذخیره شد.',
      'errorSave': 'خطا در ذخیره عکس.',
      'selectDay': 'انتخاب روز از تقویم',
    },
    'en': {
      'title': 'Shift, Overtime & Leave Planner',
      'dayShift': 'Day Shift',
      'eveningShift': 'Evening Shift',
      'nightShift': 'Night Shift',
      'overtime': 'Overtime:',
      'leave': 'Hourly Leave:',
      'saveChart': 'Save Chart Image to Gallery',
      'successSave': 'Chart saved to gallery successfully.',
      'errorSave': 'Error saving chart.',
      'selectDay': 'Select Day from Calendar',
    },
    'de': {
      'title': 'Schicht-, Überstunden- und Urlaubsplaner',
      'dayShift': 'Tagschicht',
      'eveningShift': 'Abendschicht',
      'nightShift': 'Nachtschicht',
      'overtime': 'Überstunden:',
      'leave': 'Stundenurlaub:',
      'saveChart': 'Diagramm in Galerie speichern',
      'successSave': 'Diagramm erfolgreich in Galerie gespeichert.',
      'errorSave': 'Fehler beim Speichern.',
      'selectDay': 'Tag aus Kalender auswählen',
    },
  };

  static String get(String key, String lang) {
    return translations[lang]?[key] ?? translations['fa']![key]!;
  }
}

class WorkCalendarScreen extends StatefulWidget {
  final String language;
  final Function(String) onLanguageChanged;

  const WorkCalendarScreen({
    Key? key,
    required this.language,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<WorkCalendarScreen> createState() => _WorkCalendarScreenState();
}

class _WorkCalendarScreenState extends State<WorkCalendarScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // داده‌های نمونه برای محاسبات
  double overtimeHours = 12.5;
  double leaveHours = 4.0;

  // ذخیره شیفت هر روز (کلید: شماره روز ماه، مقدار: نوع شیفت)
  final Map<int, String> _monthShifts = {};
  int _selectedDay = Jalali.now().day;

  // ثبت شیفت برای روز انتخاب شده (اصلاح منطق روزکار و عصرکار)
  void _assignShiftToSelectedDay(String shiftType) {
    setState(() {
      _monthShifts[_selectedDay] = shiftType;
    });
  }

  // ذخیره عکس نمودار در گالری
  Future<void> _captureAndSaveChart() async {
    try {
      final imageUint8List = await _screenshotController.capture();
      if (imageUint8List != null) {
        final result = await ImageGallerySaverPlus.saveImage(
          imageUint8List,
          quality: 100,
          name: "Shift_Chart_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.get('successSave', widget.language))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.get('errorSave', widget.language))),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Jalali today = Jalali.now();
    
    // محاسبه دقیق تعداد روزهای ماه شمسی
    int daysInMonth;
    if (today.month <= 6) {
      daysInMonth = 31;
    } else if (today.month <= 11) {
      daysInMonth = 30;
    } else {
      // بررسی سال کبیسه برای اسفند ماه با استفاده از متد استاندارد shamsi_date
      bool leap = Jalali(today.year, 1, 1).isLeapYear();
      daysInMonth = leap ? 30 : 29;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('title', widget.language)),
        actions: [
          // منوی انتخاب زبان (فارسی، انگلیسی، آلمانی)
          DropdownButton<String>(
            value: widget.language,
            dropdownColor: Colors.blue[800],
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'fa', child: Text('فارسی 🇮🇷')),
              DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch 🇩🇪')),
            ],
            onChanged: (lang) {
              if (lang != null) widget.onLanguageChanged(lang);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بخش محاسبه اضافه کاری و مرخصی ساعتی
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(AppStrings.get('overtime', widget.language), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('$overtimeHours ساعت', style: const TextStyle(color: Colors.green, fontSize: 16)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    Column(
                      children: [
                        Text(AppStrings.get('leave', widget.language), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('$leaveHours ساعت', style: const TextStyle(color: Colors.orange, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // تقویم ماهانه و انتخاب روز
            Text('${AppStrings.get('selectDay', widget.language)} (امروز: ${today.day})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // گرید تقویم ماه جاری
            SizedBox(
              height: 180,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  int dayNum = index + 1;
                  bool isSelected = _selectedDay == dayNum;
                  String? shift = _monthShifts[dayNum];

                  Color boxColor = Colors.grey[200]!;
                  if (shift == 'day') boxColor = Colors.yellow[200]!;
                  if (shift == 'evening') boxColor = Colors.blue[200]!;
                  if (shift == 'night') boxColor = Colors.purple[200]!;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = dayNum;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[400] : boxColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.blue[900]! : Colors.transparent, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            // دکمه‌های ثبت شیفت برای روز انتخاب شده
            Text('ثبت شیفت برای روز $_selectedDay:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: () => _assignShiftToSelectedDay('day'),
                  child: Text(AppStrings.get('dayShift', widget.language)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () => _assignShiftToSelectedDay('evening'),
                  child: Text(AppStrings.get('eveningShift', widget.language)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  onPressed: () => _assignShiftToSelectedDay('night'),
                  child: Text(AppStrings.get('nightShift', widget.language)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // بخش نمودار برای اسکرین‌شات و ذخیره در گالری
            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text('گزارش عملکرد و نمودار شیفت‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    const Icon(Icons.bar_chart, size: 70, color: Colors.blue),
                    const SizedBox(height: 10),
                    Text('مجموع شیفت‌های ثبت شده این ماه: ${_monthShifts.length} روز'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // دکمه ذخیره عکس نمودار
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _captureAndSaveChart,
                icon: const Icon(Icons.save_alt),
                label: Text(AppStrings.get('saveChart', widget.language)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
