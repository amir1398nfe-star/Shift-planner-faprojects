import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

void main() {
  runApp(const ShiftPlannerApp());
}

class ShiftPlannerApp extends StatelessWidget {
  const ShiftPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'برنامه شیفت و مرخصی',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WorkCalendarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 1. محاسبات تقویم و روزهای هفته بر اساس تاریخ شمسی
class CalendarUtils {
  static Jalali getTodayJalali() {
    return Jalali.now();
  }

  // گرفتن نام روز هفته دقیق با تقویم شمسی
  static String getPersianDayOfWeek(Jalali date) {
    // در پکیج shamsi_date مقدار weekDay از 1 (شنبه) تا 7 (جمعه) است
    switch (date.weekDay) {
      case 1: return 'شنبه';
      case 2: return 'یکشنبه';
      case 3: return 'دوشنبه';
      case 4: return 'سه‌شنبه';
      case 5: return 'چهارشنبه';
      case 6: return 'پنج‌شنبه';
      case 7: return 'جمعه';
      default: return '';
    }
  }
}

class WorkCalendarScreen extends StatefulWidget {
  const WorkCalendarScreen({Key? key}) : super(key: key);

  @override
  _WorkCalendarScreenState createState() => _WorkCalendarScreenState();
}

class _WorkCalendarScreenState extends State<WorkCalendarScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // وضعیت شیفت انتخابی
  String currentShift = 'نامشخص';

  // اصلاح منطق شیفت‌ها (تعیین درست روزکار و عصرکار)
  void assignShift(bool isDayShift) {
    setState(() {
      if (isDayShift) {
        currentShift = 'روزکار';
      } else {
        currentShift = 'عصرکار';
      }
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
          name: "Chart_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عکس نمودار با موفقیت در گالری ذخیره شد.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در ذخیره عکس در گالری.')),
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
    String dayName = CalendarUtils.getPersianDayOfWeek(today);

    return Scaffold(
      appBar: AppBar(
        title: Text('تقویم شیفت‌ها - امروز: $dayName ${today.day} ${today.formatter.monthName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('شیفت ثبت شده امروز: $currentShift', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => assignShift(true),
                  child: const Text('ثبت روزکار'),
                ),
                ElevatedButton(
                  onPressed: () => assignShift(false),
                  child: const Text('ثبت عصرکار'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // بخش نمودار برای اسکرین‌شات
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.amber[100],
                padding: const EdgeInsets.all(24.0),
                child: const Column(
                  children: [
                    Text('نمودار عملکرد و ساعات کاری', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 10),
                    Icon(Icons.bar_chart, size: 50, color: Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _captureAndSaveChart,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره عکس نمودار در گالری'),
            ),
          ],
        ),
      ),
    );
  }
}
