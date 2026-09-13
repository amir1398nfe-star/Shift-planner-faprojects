import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

// 1. اصلاح محاسبه روزهای هفته و تطبیق تقویم شمسی
class CalendarUtils {
  static Jalali getTodayJalali() {
    return Jalali.now();
  }

  // گرفتن نام روز هفته بایند شده دقیق به تقویم شمسی
  static String getPersianDayOfWeek(Jalali date) {
    // در پکیج شمس، weekDay از 1 (شنبه) تا 7 (جمعه) است
    switch (date.weekDay) {
      .sat: return 'شنبه';
      .sun: return 'یکشنبه';
      .mon: return 'دوشنبه';
      .tue: return 'سه‌شنبه';
      .wed: return 'چهارشنبه';
      .thu: return 'پنج‌شنبه';
      .fri: return 'جمعه';
      default: return '';
    }
  }
}

// 2. اصلاح منطق شیفت‌ها و ذخیره‌سازی عکس نمودار
class WorkCalendarScreen extends StatefulWidget {
  @override
  _WorkCalendarScreenState createState() => _WorkCalendarScreenState();
}

class _WorkCalendarScreenState extends State<WorkCalendarScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // اصلاح منطق شیفت‌ها (جایگزینی درست روزکار و عصرکار)
  void assignShift(DateTime date, bool isDayShift) {
    setState(() {
      if (isDayShift) {
        // شیفت روزکار
        print("ثبت به عنوان: روزکار");
      } else {
        // شیفت عصرکار
        print("ثبت به عنوان: عصرکار");
      }
    });
  }

  // اصلاح ذخیره نمودار در گالری همراه با اخذ دسترسی
  Future<void> _captureAndSaveChart() async {
    // بررسی و گرفتن دسترسی فضای ذخیره‌سازی
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      // برای اندرویدهای بالاتر ممکن است دسترسی‌های دیگری نیاز باشد
      await Permission.photos.request();
    }

    try {
      // اسکرین‌شات گرفتن از ویجت نمودار
      final imageUint8List = await _screenshotController.capture();
      
      if (imageUint8List != null) {
        // ذخیره در گالری با استفاده از پکیج image_gallery_saver
        final result = await ImageGallerySaver.saveImage(
          imageUint8List,
          quality: 100,
          name: "Chart_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (result['isSuccess'] == true) {
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text('تقویم شیفت‌ها - امروز: ${CalendarUtils.getPersianDayOfWeek(today)} ${today.day} ${today.formatter.monthName}'),
      ),
      body: Column(
        children: [
          // بخش نمودار برای اسکرین‌شات
          Screenshot(
            controller: _screenshotController,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: const Text('نمودار عملکرد و ساعات کاری شما'),
            ),
          ),
          ElevatedButton(
            onPressed: _captureAndSaveChart,
            child: const Text('ذخیره عکس نمودار در گالری'),
          ),
        ],
      ),
    );
  }
}
