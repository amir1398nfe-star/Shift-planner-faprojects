import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShiftTrackerApp());
}

class ShiftTrackerApp extends StatelessWidget {
  const ShiftTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت شیفت و کارکرد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainContainerScreen(),
    );
  }
}

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({Key? key}) : super(key: key);

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ShamsiCalendarScreen(),
    const ReportsChartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex],
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'تقویم و شیفت‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'گزارش و نمودار',
          ),
        ],
      ),
    );
  }
}

class ShamsiCalendarScreen extends StatefulWidget {
  const ShamsiCalendarScreen({Key? key}) : super(key: key);

  @override
  State<ShamsiCalendarScreen> createState() => _ShamsiCalendarScreenState();
}

class _ShamsiCalendarScreenState extends State<ShamsiCalendarScreen> {
  final List<String> shamsiMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  int currentMonthIndex = 5; // پیش‌فرض شهریور
  int currentYear = 1405;

  final List<String> weekDays = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'
  ];

  // ذخیره وضعیت روزها (overtime, daily_leave, hourly_leave)
  final Map<String, String> dayStatuses = {};
  int totalOvertime = 0;
  int totalLeaveDays = 0;
  int totalLeaveHours = 0;
  String currentShiftType = 'عادی';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalOvertime = prefs.getInt('total_overtime') ?? 0;
      totalLeaveDays = prefs.getInt('total_leave_days') ?? 0;
      totalLeaveHours = prefs.getInt('total_leave_hours') ?? 0;
      currentShiftType = prefs.getString('current_shift_type') ?? 'عادی';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_overtime', totalOvertime);
    await prefs.setInt('total_leave_days', totalLeaveDays);
    await prefs.setInt('total_leave_hours', totalLeaveHours);
    await prefs.setString('current_shift_type', currentShiftType);
  }

  void _previousMonth() {
    setState(() {
      if (currentMonthIndex > 0) {
        currentMonthIndex--;
      } else {
        currentMonthIndex = 11;
        currentYear--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (currentMonthIndex < 11) {
        currentMonthIndex++;
      } else {
        currentMonthIndex = 0;
        currentYear++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // هدر مجموع عملکرد
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('اضافه‌کار', '$totalOvertime ساعت', Icons.timer),
              Container(height: 35, width: 1, color: Colors.white30),
              _buildHeaderStat('مرخصی روزانه', '$totalLeaveDays روز', Icons.event_busy),
              Container(height: 35, width: 1, color: Colors.white30),
              _buildHeaderStat('مرخصی ساعتی', '$totalLeaveHours ساعت', Icons.hourglass_bottom),
            ],
          ),
        ),

        // انتخاب نوع شیفت و دکمه تنظیمات
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('شیفت فعلی: $currentShiftType', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ElevatedButton.icon(
                onPressed: _showShiftConfigModal,
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('انتخاب شیفت'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // نوار جابه‌جایی ماه‌ها
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _nextMonth, icon: const Icon(Icons.arrow_forward_ios, size: 18), color: Colors.deepPurple),
              Text('${shamsiMonths[currentMonthIndex]} $currentYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              IconButton(onPressed: _previousMonth, icon: const Icon(Icons.arrow_back_ios, size: 18), color: Colors.deepPurple),
            ],
          ),
        ),

        // اسامی حروفی روزهای هفته
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              bool isFri = day == 'جمعه';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isFri ? Colors.red.shade700 : Colors.grey.shade700),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(),

        // تقویم ماهانه
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              int dayNum = index + 1;
              bool isFriday = (index % 7 == 6);
              String key = '$currentYear-$currentMonthIndex-$dayNum';
              String? status = dayStatuses[key];

              Color bgColor = isFriday ? Colors.red.shade50 : Colors.white;
              Color borderColor = isFriday ? Colors.red.shade200 : Colors.grey.shade300;
              Color textColor = isFriday ? Colors.red.shade800 : Colors.black87;

              if (status == 'overtime') {
                bgColor = Colors.purple.shade50;
                borderColor = Colors.purple.shade300;
              } else if (status == 'leave_daily' || status == 'leave_hourly') {
                bgColor = Colors.orange.shade50;
                borderColor = Colors.orange.shade300;
              }

              return InkWell(
                onTap: () => _showDaySettingsModal(dayNum, key),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      const SizedBox(height: 2),
                      Icon(
                        status != null ? Icons.bookmark : Icons.work_outline,
                        size: 10,
                        color: status != null ? Colors.deepPurple : (isFriday ? Colors.red.shade400 : Colors.grey),
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
  }

  Widget _buildHeaderStat(String title, String val, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  void _showShiftConfigModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempShift = currentShiftType;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('انتخاب نوع شیفت کاری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: tempShift,
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: ['عادی', 'صبح‌کار', 'عصر‌کار', 'شب‌کار', 'گردشی', 'استراحت'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setModalState(() => tempShift = val!),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() => currentShiftType = tempShift);
                          _saveData();
                          Navigator.pop(context);
                        },
                        child: const Text('ذخیره شیفت'),
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

  void _showDaySettingsModal(int dayNum, String key) {
    final TextEditingController otController = TextEditingController();
    final TextEditingController leaveHourController = TextEditingController();
    String leaveType = 'بدون مرخصی';

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
                        Text('تنظیمات روز $dayNum ${shamsiMonths[currentMonthIndex]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 15),
                        TextField(
                          controller: otController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'ساعت اضافه‌کار', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: leaveType,
                          decoration: InputDecoration(labelText: 'نوع مرخصی', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          items: ['بدون مرخصی', 'مرخصی روزانه', 'مرخصی ساعتی'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setModalState(() => leaveType = val!),
                        ),
                        if (leaveType == 'مرخصی ساعتی') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: leaveHourController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'تعداد ساعت مرخصی', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                          onPressed: () {
                            int ot = int.tryParse(otController.text) ?? 0;
                            setState(() {
                              if (ot > 0) {
                                totalOvertime += ot;
                                dayStatuses[key] = 'overtime';
                              }
                              if (leaveType == 'مرخصی روزانه') {
                                totalLeaveDays += 1;
                                dayStatuses[key] = 'leave_daily';
                              } else if (leaveType == 'مرخصی ساعتی') {
                                int lh = int.tryParse(leaveHourController.text) ?? 0;
                                totalLeaveHours += lh;
                                dayStatuses[key] = 'leave_hourly';
                              }
                            });
                            _saveData();
                            Navigator.pop(context);
                          },
                          child: const Text('ثبت تغییرات و رنگ‌آمیزی روز'),
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
  const ReportsChartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نمودار عملکرد و مقایسه ماه‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart, size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  const Text('نمودار مقایسه‌ای اضافه‌کار و مرخصی‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text('اطلاعات ماه‌های گذشته به صورت نمودار ستونی اینجا نمایش داده می‌شود.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
