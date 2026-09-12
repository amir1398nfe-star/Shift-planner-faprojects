import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // اشتراک‌گذاری داده‌های ماهانه بین تقویم و نمودار برای به‌روزرسانی لحظه‌ای
  Map<String, Map<String, dynamic>> monthlyData = {};
  int currentMonthIndex = 5; // پیش‌فرض شهریور
  int currentYear = 1404;
  final List<String> shamsiMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  @override
  void initState() {
    super.initState();
    _loadGlobalData();
  }

  Future<void> _loadGlobalData() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('saved_monthly_tracker_data');
    setState(() {
      if (storedData != null) {
        Map<String, dynamic> decoded = jsonDecode(storedData);
        monthlyData = decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      }
    });
  }

  Future<void> _saveGlobalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_monthly_tracker_data', jsonEncode(monthlyData));
  }

  void updateMonthlyData(Map<String, Map<String, dynamic>> newData) {
    setState(() {
      monthlyData = newData;
    });
    _saveGlobalData();
  }

  void changeMonth(int year, int monthIndex) {
    setState(() {
      currentYear = year;
      currentMonthIndex = monthIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ShamsiCalendarScreen(
        monthlyData: monthlyData,
        currentYear: currentYear,
        currentMonthIndex: currentMonthIndex,
        onDataChanged: updateMonthlyData,
        onMonthChanged: changeMonth,
      ),
      ReportsChartScreen(
        monthlyData: monthlyData,
        currentYear: currentYear,
        currentMonthIndex: currentMonthIndex,
        shamsiMonths: shamsiMonths,
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
  final Map<String, Map<String, dynamic>> monthlyData;
  final int currentYear;
  final int currentMonthIndex;
  final Function(Map<String, Map<String, dynamic>>) onDataChanged;
  final Function(int, int) onMonthChanged;

  const ShamsiCalendarScreen({
    Key? key,
    required this.monthlyData,
    required this.currentYear,
    required this.currentMonthIndex,
    required this.onDataChanged,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  State<ShamsiCalendarScreen> createState() => _ShamsiCalendarScreenState();
}

class _ShamsiCalendarScreenState extends State<ShamsiCalendarScreen> {
  final List<String> shamsiMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  final List<String> weekDays = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'
  ];

  String currentShiftType = 'عادی';

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentShiftType = prefs.getString('current_shift_type') ?? 'عادی';
    });
  }

  Future<void> _saveShift(String shift) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_shift_type', shift);
  }

  String get _currentMonthKey => '${widget.currentYear}-${widget.currentMonthIndex}';

  int get currentMonthOvertime {
    final monthMap = widget.monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['overtime'] != null) {
        total += int.tryParse(data['overtime'].toString()) ?? 0;
      }
    });
    return total;
  }

  int get currentMonthLeaveDays {
    final monthMap = widget.monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['status'] == 'leave_daily') {
        total += 1;
      }
    });
    return total;
  }

  int get currentMonthLeaveHours {
    final monthMap = widget.monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['leave_hours'] != null) {
        total += int.tryParse(data['leave_hours'].toString()) ?? 0;
      }
    });
    return total;
  }

  void _previousMonth() {
    int y = widget.currentYear;
    int m = widget.currentMonthIndex;
    if (m > 0) {
      m--;
    } else {
      m = 11;
      y--;
    }
    widget.onMonthChanged(y, m);
  }

  void _nextMonth() {
    int y = widget.currentYear;
    int m = widget.currentMonthIndex;
    if (m < 11) {
      m++;
    } else {
      m = 0;
      y++;
    }
    widget.onMonthChanged(y, m);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // هدر مجموع عملکرد ماه جاری
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
              _buildHeaderStat('اضافه‌کار', '$currentMonthOvertime ساعت', Icons.timer),
              Container(height: 35, width: 1, color: Colors.white30),
              _buildHeaderStat('مرخصی روزانه', '$currentMonthLeaveDays روز', Icons.event_busy),
              Container(height: 35, width: 1, color: Colors.white30),
              _buildHeaderStat('مرخصی ساعتی', '$currentMonthLeaveHours ساعت', Icons.hourglass_bottom),
            ],
          ),
        ),

        // انتخاب شیفت
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
              Text('${shamsiMonths[widget.currentMonthIndex]} ${widget.currentYear}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              IconButton(onPressed: _previousMonth, icon: const Icon(Icons.arrow_back_ios, size: 18), color: Colors.deepPurple),
            ],
          ),
        ),

        // روزهای هفته
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

        // تقویم
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              int dayNum = index + 1;
              bool isFriday = (index % 7 == 6);
              
              final monthMap = widget.monthlyData[_currentMonthKey] ?? {};
              final dayData = monthMap[dayNum.toString()] as Map<String, dynamic>?;

              String? status = dayData?['status'];
              String? otVal = dayData?['overtime'];
              String? lhVal = dayData?['leave_hours'];

              Color bgColor = isFriday ? Colors.red.shade50 : Colors.white;
              Color borderColor = isFriday ? Colors.red.shade200 : Colors.grey.shade300;
              Color textColor = isFriday ? Colors.red.shade800 : Colors.black87;

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
                onTap: () => _showDaySettingsModal(dayNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                      const SizedBox(height: 2),
                      if (otVal != null && otVal.isNotEmpty && otVal != '0')
                        Text('+${otVal} ک', style: TextStyle(fontSize: 9, color: Colors.purple.shade800, fontWeight: FontWeight.bold)),
                      if (status == 'leave_daily')
                        const Text('م.روزانه', style: TextStyle(fontSize: 8, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                      if (lhVal != null && lhVal.isNotEmpty && lhVal != '0')
                        Text('${lhVal}س م', style: TextStyle(fontSize: 9, color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
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
                          _saveShift(tempShift);
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

  void _showDaySettingsModal(int dayNum) {
    final monthMap = widget.monthlyData[_currentMonthKey] ?? {};
    final dayData = monthMap[dayNum.toString()] as Map<String, dynamic>?;

    final TextEditingController otController = TextEditingController(text: dayData?['overtime'] ?? '');
    final TextEditingController leaveHourController = TextEditingController(text: dayData?['leave_hours'] ?? '');
    String leaveType = dayData?['status'] ?? 'بدون مرخصی';
    if (leaveType != 'مرخصی روزانه' && leaveType != 'مرخصی ساعتی') {
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
                        Text('تنظیمات روز $dayNum ${shamsiMonths[widget.currentMonthIndex]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                            String ot = otController.text.trim();
                            String lh = leaveHourController.text.trim();

                            Map<String, Map<String, dynamic>> updatedData = Map.from(widget.monthlyData);
                            if (updatedData[_currentMonthKey] == null) {
                              updatedData[_currentMonthKey] = {};
                            }

                            String finalStatus = 'normal';
                            if (leaveType == 'مرخصی روزانه') {
                              finalStatus = 'leave_daily';
                            } else if (leaveType == 'مرخصی ساعتی') {
                              finalStatus = 'leave_hourly';
                            } else if (ot.isNotEmpty && ot != '0') {
                              finalStatus = 'overtime';
                            }

                            updatedData[_currentMonthKey]![dayNum.toString()] = {
                              'status': finalStatus,
                              'overtime': ot,
                              'leave_hours': leaveType == 'مرخصی ساعتی' ? lh : '',
                            };

                            widget.onDataChanged(updatedData);
                            Navigator.pop(context);
                          },
                          child: const Text('ثبت تغییرات و نمایش روی روز'),
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

// صفحه گزارش و نمودار به صورت کاملاً لحظه‌ای و برخط متصل به ماه جاری
class ReportsChartScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> monthlyData;
  final int currentYear;
  final int currentMonthIndex;
  final List<String> shamsiMonths;

  const ReportsChartScreen({
    Key? key,
    required this.monthlyData,
    required this.currentYear,
    required this.currentMonthIndex,
    required this.shamsiMonths,
  }) : super(key: key);

  String get _currentMonthKey => '$currentYear-$currentMonthIndex';

  int get totalOvertime {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['overtime'] != null) {
        total += int.tryParse(data['overtime'].toString()) ?? 0;
      }
    });
    return total;
  }

  int get totalLeaveDays {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['status'] == 'leave_daily') {
        total += 1;
      }
    });
    return total;
  }

  int get totalLeaveHours {
    final monthMap = monthlyData[_currentMonthKey] ?? {};
    int total = 0;
    monthMap.forEach((day, data) {
      if (data is Map && data['leave_hours'] != null) {
        total += int.tryParse(data['leave_hours'].toString()) ?? 0;
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    String monthName = shamsiMonths[currentMonthIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'گزارش برخط و لحظه‌ای عملکرد $monthName $currentYear',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          
          // کارت‌های خلاصه وضعیت لحظه‌ای
          Row(
            children: [
              Expanded(
                child: _buildReportCard('مجموع اضافه‌کار', '$totalOvertime ساعت', Colors.purple.shade50, Colors.purple.shade800, Icons.timer),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReportCard('مرخصی روزانه', '$totalLeaveDays روز', Colors.orange.shade50, Colors.orange.shade800, Icons.event_busy),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReportCard('مرخصی ساعتی', '$totalLeaveHours ساعت', Colors.teal.shade50, Colors.teal.shade800, Icons.hourglass_bottom),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text('نمودار میله‌ای مقایسه‌ای (برخط)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // محفظه نمودار زنده
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
                  // شبیه‌سازی میله‌های نمودار زنده بر اساس مقادیر واقعی ثبت شده
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('اضافه‌کار', totalOvertime.toDouble(), 100, Colors.purple),
                      _buildBar('م. روزانه', (totalLeaveDays * 8).toDouble(), 100, Colors.orange), // فرض ۸ ساعت در روز
                      _buildBar('م. ساعتی', totalLeaveHours.toDouble(), 100, Colors.teal),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text(
                    'این نمودار به صورت کاملاً لحظه‌ای با تغییرات تقویم شما به‌روز می‌شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
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

  Widget _buildBar(String label, double value, double maxVal, Color color) {
    double heightFactor = (value / (maxVal == 0 ? 1 : maxVal)).clamp(0.05, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${value.toInt()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Container(
          width: 35,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
