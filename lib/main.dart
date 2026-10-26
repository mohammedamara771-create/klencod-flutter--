import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const TempoClockApp());
}

const Color backgroundColor = Color(0xFF0D1117);
const Color cardColor = Color(0xFF161B22);
const Color accentColor = Color(0xFF00E5A8);

class TempoClockApp extends StatelessWidget {
  const TempoClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ساعة',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ClockHomePage(),
    );
  }
}

class ClockHomePage extends StatefulWidget {
  const ClockHomePage({super.key});

  @override
  State<ClockHomePage> createState() => _ClockHomePageState();
}

class _ClockHomePageState extends State<ClockHomePage> {
  int selectedTab = 0;

  Timer? clockTimer;
  Timer? stopwatchTimer;
  Timer? countdownTimer;

  DateTime currentTime = DateTime.now();

  int stopwatchMilliseconds = 0;
  bool stopwatchRunning = false;

  int countdownSeconds = 300;
  int initialCountdownSeconds = 300;
  bool countdownRunning = false;

  @override
  void initState() {
    super.initState();

    clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            currentTime = DateTime.now();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    stopwatchTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  String twoDigits(int value) => value.toString().padLeft(2, '0');

  String formatTime(DateTime time) {
    return '${twoDigits(time.hour)}:'
        '${twoDigits(time.minute)}:'
        '${twoDigits(time.second)}';
  }

  String formatStopwatch(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final centiseconds = (duration.inMilliseconds % 1000) ~/ 10;

    return '${twoDigits(minutes)}:'
        '${twoDigits(seconds)}.'
        '${twoDigits(centiseconds)}';
  }

  String formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${twoDigits(minutes)}:${twoDigits(remainingSeconds)}';
  }

  void startStopwatch() {
    if (stopwatchRunning) return;

    setState(() {
      stopwatchRunning = true;
    });

    stopwatchTimer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) {
        if (mounted && stopwatchRunning) {
          setState(() {
            stopwatchMilliseconds += 10;
          });
        }
      },
    );
  }

  void pauseStopwatch() {
    stopwatchTimer?.cancel();

    setState(() {
      stopwatchRunning = false;
    });
  }

  void resetStopwatch() {
    stopwatchTimer?.cancel();

    setState(() {
      stopwatchRunning = false;
      stopwatchMilliseconds = 0;
    });
  }

  void startCountdown() {
    if (countdownRunning || countdownSeconds <= 0) return;

    setState(() {
      countdownRunning = true;
    });

    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (countdownSeconds <= 1) {
          countdownTimer?.cancel();

          setState(() {
            countdownSeconds = 0;
            countdownRunning = false;
          });

          return;
        }

        setState(() {
          countdownSeconds--;
        });
      },
    );
  }

  void pauseCountdown() {
    countdownTimer?.cancel();

    setState(() {
      countdownRunning = false;
    });
  }

  void resetCountdown() {
    countdownTimer?.cancel();

    setState(() {
      countdownRunning = false;
      countdownSeconds = initialCountdownSeconds;
    });
  }

  Future<void> chooseCountdownDuration() async {
    if (countdownRunning) return;

    int minutes = countdownSeconds ~/ 60;
    int seconds = countdownSeconds % 60;

    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: const Text(
                'ضبط المؤقت',
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('اختر المدة بالدقائق والثواني'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text('الدقائق'),
                          DropdownButton<int>(
                            value: minutes,
                            items: List.generate(121, (index) {
                              return DropdownMenuItem(
                                value: index,
                                child: Text('$index'),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                updateDialog(() {
                                  minutes = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 25),
                      Column(
                        children: [
                          const Text('الثواني'),
                          DropdownButton<int>(
                            value: seconds,
                            items: List.generate(60, (index) {
                              return DropdownMenuItem(
                                value: index,
                                child: Text('$index'),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                updateDialog(() {
                                  seconds = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      [minutes, seconds],
                    );
                  },
                  child: const Text('تأكيد'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      final totalSeconds = result[0] * 60 + result[1];

      setState(() {
        initialCountdownSeconds = totalSeconds;
        countdownSeconds = totalSeconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildClockPage(),
      buildStopwatchPage(),
      buildCountdownPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: backgroundColor,
          title: const Row(
            children: [
              Icon(Icons.access_time, color: accentColor),
              SizedBox(width: 10),
              Text(
                'ساعة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'معلومات التطبيق',
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'ساعة',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'تطبيق ساعة بسيط وأنيق',
                );
              },
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: pages[selectedTab],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: cardColor,
          indicatorColor: accentColor.withValues(alpha: 0.18),
          selectedIndex: selectedTab,
          onDestinationSelected: (index) {
            setState(() {
              selectedTab = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(
                Icons.schedule,
                color: accentColor,
              ),
              label: 'الساعة',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(
                Icons.timer,
                color: accentColor,
              ),
              label: 'الإيقاف',
            ),
            NavigationDestination(
              icon: Icon(Icons.hourglass_bottom),
              selectedIcon: Icon(
                Icons.hourglass_bottom,
                color: accentColor,
              ),
              label: 'المؤقت',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildClockPage() {
    final date =
        '${currentTime.year}/${twoDigits(currentTime.month)}/'
        '${twoDigits(currentTime.day)}';

    return SingleChildScrollView(
      key: const ValueKey('clock'),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Icon(
            Icons.wb_sunny_outlined,
            color: accentColor,
            size: 55,
          ),
          const SizedBox(height: 25),
          const Text(
            'الوقت الآن',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatTime(currentTime),
              style: const TextStyle(
                fontSize: 65,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            date,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 45),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white10,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: accentColor,
                  size: 35,
                ),
                SizedBox(height: 15),
                Text(
                  'وقتك بين يديك',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ساعة بسيطة لقياس الوقت وتنظيم يومك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStopwatchPage() {
    return SingleChildScrollView(
      key: const ValueKey('stopwatch'),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 35),
          const Icon(
            Icons.timer,
            color: accentColor,
            size: 55,
          ),
          const SizedBox(height: 25),
          const Text(
            'ساعة الإيقاف',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatStopwatch(stopwatchMilliseconds),
              style: const TextStyle(
                fontSize: 58,
                color: accentColor,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              actionButton(
                icon: stopwatchRunning
                    ? Icons.pause
                    : Icons.play_arrow,
                label: stopwatchRunning ? 'إيقاف مؤقت' : 'ابدأ',
                onPressed: stopwatchRunning
                    ? pauseStopwatch
                    : startStopwatch,
                primary: true,
              ),
              const SizedBox(width: 15),
              actionButton(
                icon: Icons.refresh,
                label: 'إعادة',
                onPressed: resetStopwatch,
                primary: false,
              ),
            ],
          ),
          const SizedBox(height: 35),
          const Text(
            'ابدأ لقياس الوقت، ثم أوقفه أو أعده للصفر.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCountdownPage() {
    final progress = initialCountdownSeconds > 0
        ? countdownSeconds / initialCountdownSeconds
        : 0.0;

    return SingleChildScrollView(
      key: const ValueKey('countdown'),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Icon(
            Icons.hourglass_bottom,
            color: accentColor,
            size: 55,
          ),
          const SizedBox(height: 20),
          const Text(
            'المؤقت التنازلي',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 245,
            height: 245,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: Colors.white10,
                    color: accentColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatCountdown(countdownSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        color: accentColor,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      countdownRunning
                          ? 'جارٍ العد'
                          : countdownSeconds == 0
                              ? 'انتهى الوقت'
                              : 'متوقف',
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          OutlinedButton.icon(
            onPressed: chooseCountdownDuration,
            icon: const Icon(Icons.edit),
            label: const Text('تغيير المدة'),
          ),
          const SizedBox(height: 25),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              actionButton(
                icon: countdownRunning
                    ? Icons.pause
                    : Icons.play_arrow,
                label: countdownRunning ? 'إيقاف مؤقت' : 'ابدأ',
                onPressed: countdownRunning
                    ? pauseCountdown
                    : startCountdown,
                primary: true,
              ),
              actionButton(
                icon: Icons.refresh,
                label: 'إعادة',
                onPressed: resetCountdown,
                primary: false,
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'المدة الافتراضية خمس دقائق.',
            style: TextStyle(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool primary,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primary ? accentColor : cardColor,
        foregroundColor: primary ? backgroundColor : Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}