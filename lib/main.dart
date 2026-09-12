
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
        fontFamily: 'Vazirmatn', // Assuming standard font or fallback
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const ShiftHomeScreen(),
    );
  }
}

class ShiftHomeScreen extends StatefulWidget {
  const ShiftHomeScreen({Key? key}) : super(key: key);

  @override
  State<ShiftHomeScreen> createState() => _ShiftHomeScreenState();
}

class _ShiftHomeScreenState extends State<ShiftHomeScreen> {
  int totalOvertime = 0; // Default zero-initialization
  int totalLeaveDays = 0; // Default zero-initialization
  int totalLeaveHours = 0; // Default zero-initialization
  
  String currentShiftType = 'عادی'; // Default shift type
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Mandatory zero-initialization for new users
      totalOvertime = prefs.getInt('total_overtime') ?? 0;
      totalLeaveDays = prefs.getInt('total_leave_days') ?? 0;
      totalLeaveHours = prefs.getInt('total_leave_hours') ?? 0;
      currentShiftType = prefs.getString('current_shift_type') ?? 'عادی';
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_overtime', totalOvertime);
    await prefs.setInt('total_leave_days', totalLeaveDays);
    await prefs.setInt('total_leave_hours', totalLeaveHours);
    await prefs.setString('current_shift_type', currentShiftType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStatItem('اضافه کار ماه', '$totalOvertime ساعت', Icons.timer),
                  Container(height: 40, width: 1, color: Colors.white30),
                  _buildHeaderStatItem('مرخصی روزانه', '$totalLeaveDays روز', Icons.event_busy),
                  Container(height: 40, width: 1, color: Colors.white30),
                  _buildHeaderStatItem('مرخصی ساعتی', '$totalLeaveHours ساعت', Icons.hourglass_bottom),
                ],
              ),
            ),

            // Shift Configuration Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'شیفت کاری: $currentShiftType',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showShiftConfigModal,
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('تنظیم شیفت'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Calendar Header: Full Weekday Names
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'
                ].map((day) {
                  bool isFri = day == 'جمعه';
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isFri ? Colors.red.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(),

            // Calendar Grid Area (Simulated 30 Days of Shahrivar)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 31,
                itemBuilder: (context, index) {
                  int dayNum = index + 1;
                  // Friday condition check (assuming index % 7 == 6 is Friday in this layout)
                  bool isFriday = (index % 7 == 6);

                  return InkWell(
                    onTap: () => _showDaySettingsModal(dayNum),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isFriday ? Colors.red.shade50 : Colors.white,
                        border: Border.all(
                          color: isFriday ? Colors.red.shade200 : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isFriday ? Colors.red.shade800 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.work_outline,
                            size: 12,
                            color: isFriday ? Colors.red.shade400 : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatItem(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
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
                      const Text(
                        'تنظیم شیفت کاری',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: tempShift,
                        decoration: InputDecoration(
                          labelText: 'انتخاب نوع شیفت',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['عادی', 'صبحکار', 'عصرکار', 'شب‌کار', 'گردشی'].map((shift) {
                          return DropdownMenuItem(value: shift, child: Text(shift));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              tempShift = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setState(() {
                            currentShiftType = tempShift;
                          });
                          _saveUserData();
                          Navigator.pop(context);
                        },
                        child: const Text('ذخیره تنظیمات شیفت', style: TextStyle(fontSize: 16)),
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

  void _showDaySettingsModal(int dayNumber) {
    final TextEditingController overtimeController = TextEditingController();
    final TextEditingController hourlyLeaveController = TextEditingController();
    String leaveType = 'بدون مرخصی';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تنظیمات روز $dayNumber شهریور',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // Overtime input
                        TextField(
                          controller: overtimeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'ساعت اضافه‌کار',
                            prefixIcon: const Icon(Icons.timer_outlined, color: Colors.deepPurple),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Leave type dropdown (Daily vs Hourly separation)
                        DropdownButtonFormField<String>(
                          value: leaveType,
                          decoration: InputDecoration(
                            labelText: 'وضعیت مرخصی',
                            prefixIcon: const Icon(Icons.event_note, color: Colors.deepPurple),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: ['بدون مرخصی', 'مرخصی روزانه', 'مرخصی ساعتی'].map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                leaveType = val;
                              });
                            }
                          },
                        ),
                        
                        // Conditional Hourly Leave Input Field
                        if (leaveType == 'مرخصی ساعتی') ...[
                          const SizedBox(height: 15),
                          TextField(
                            controller: hourlyLeaveController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'تعداد ساعت مرخصی ساعتی',
                              prefixIcon: const Icon(Icons.hourglass_top, color: Colors.orange),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 25),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            int addedOvertime = int.tryParse(overtimeController.text) ?? 0;
                            
                            setState(() {
                              totalOvertime += addedOvertime;
                              if (leaveType == 'مرخصی روزانه') {
                                totalLeaveDays += 1;
                              } else if (leaveType == 'مرخصی ساعتی') {
                                int addedHours = int.tryParse(hourlyLeaveController.text) ?? 0;
                                totalLeaveHours += addedHours;
                              }
                            });
                            _saveUserData();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تغییرات با موفقیت ثبت شد')),
                            );
                          },
                          child: const Text('ثبت و ذخیره تغییرات', style: TextStyle(fontSize: 16)),
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
