import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/physics.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/cupertino.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDoList',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF121212),
        useMaterial3: true,
        fontFamily: 'Roboto', 
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _selectedDate = DateTime.now();
  
  final String _studentName = "Muhammad Fierlyan Irwandi";
  
  // list task (key: "YYYY-MM-DD") 
  final Map<String, List<String>> _tasksByDate = {};
  final Map<String, Set<int>> _completedByDate = {};

  // helper tanggal
  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // getter pilihan tanggal hari ini
  List<String> get _currentTodoList {
    final key = _getDateKey(_selectedDate);
    if (!_tasksByDate.containsKey(key)) {
      // seed data minimal 3
      if (isSameDay(date: _selectedDate, other: DateTime.now()) && _tasksByDate.isEmpty) {
        _tasksByDate[key] = [
          "Tulis jurnal",
          "Cari jajan",
          "Istirahat",
          "Belajar hal baru",
          "Reminder besok UAS!",
          "Nonton film",
        ];
      } else {
        _tasksByDate[key] = [];
      }
    }
    return _tasksByDate[key]!;
  }

  Set<int> get _currentCompletedItems {
    final key = _getDateKey(_selectedDate);
    if (!_completedByDate.containsKey(key)) {
      _completedByDate[key] = {};
    }
    return _completedByDate[key]!;
  }

  final TextEditingController _textController = TextEditingController();
  late ScrollController _scrollController;

  double get _expandedHeight => MediaQuery.of(context).size.height * 0.80;
  final double _toolbarHeight = 100.0;
  final double _calendarHeight = 80.0;
  
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  double _currentVelocity = 0.0;
  DateTime? _lastUpdateTime;
  double _lastOffset = 0.0;

  bool _isControllerInitialized = false;
  Timer? _greetingTimer;
  late PageController _pageController;
  final int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _loadData();
    _startGreetingTimer();
  }

  void _startGreetingTimer() {
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // load tasks
    final tasksString = prefs.getString('${_studentName}_tasks') ?? prefs.getString('tasksByDate');
    if (tasksString != null) {
      final Map<String, dynamic> decoded = jsonDecode(tasksString);
      setState(() {
        _tasksByDate.clear();
        decoded.forEach((key, value) {
          _tasksByDate[key] = List<String>.from(value);
        });
      });
    } else {
       _seedInitialData();
    }

    // load completed items
    final completedString = prefs.getString('${_studentName}_completed') ?? prefs.getString('completedByDate');
    if (completedString != null) {
      final Map<String, dynamic> decoded = jsonDecode(completedString);
      setState(() {
        _completedByDate.clear();
        decoded.forEach((key, value) {
          _completedByDate[key] = Set<int>.from(value);
        });
      });
    }
  }

  void _seedInitialData() {
    final todayKey = _getDateKey(DateTime.now());
    _tasksByDate[todayKey] = [
      "Plan a day",
      "Get sunlight",
      "Take a break",
      "Write in journal",
      "Prioritize tasks",
      "Create something new",
    ];
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_studentName}_tasks', jsonEncode(_tasksByDate));
    final completedMap = _completedByDate.map((key, value) => MapEntry(key, value.toList()));
    await prefs.setString('${_studentName}_completed', jsonEncode(completedMap));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isControllerInitialized) {
      _scrollController = ScrollController(
        initialScrollOffset: _expandedHeight,
      );
      _isControllerInitialized = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _greetingTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good morning,";
    } else if (hour >= 12 && hour < 18) {
      return "Good afternoon,";
    } else {
      return "Good night,";
    }
  }

  IconData get _greetingIcon {
    return LucideIcons.checkSquare;
  }

  void _addTask(String task, {DateTime? date}) {
    if (task.trim().isEmpty) return;
    
    final targetDate = date ?? _selectedDate;
    final key = _getDateKey(targetDate);

    setState(() {
      if (_tasksByDate[key] == null) {
        _tasksByDate[key] = [];
      }
      _tasksByDate[key]!.add(task);
    });
    _saveData();
    _textController.clear();
    Navigator.pop(context);
  }

  void _removeTask(int index) {
    setState(() {
      _currentTodoList.removeAt(index);
      final newCompleted = <int>{};
      final currentCompleted = _currentCompletedItems;
      for (final i in currentCompleted) {
        if (i < index) {
          newCompleted.add(i);
        } else if (i > index) {
          newCompleted.add(i - 1);
        }
      }
      currentCompleted.clear();
      currentCompleted.addAll(newCompleted);
    });
    _saveData();
  }

  void _toggleTask(int index) {
    setState(() {
      final currentCompleted = _currentCompletedItems;
      if (currentCompleted.contains(index)) {
        currentCompleted.remove(index);
      } else {
        currentCompleted.add(index);
      }
    });
    _saveData();
  }

  // tanggal helper
  bool isSameDay({required DateTime date, required DateTime other}) {
    return date.year == other.year && date.month == other.month && date.day == other.day;
  }

  List<DateTime> _generateWeekDays(int pageIndex) {
    final now = DateTime.now();
    // mulai dari senin per minggu
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final startOfCurrentWeek = now.subtract(Duration(days: currentWeekday - 1));
    
    // hitung mulai minggu ke berapa berdasarkan pageIndex
    final startOfTargetWeek = startOfCurrentWeek.add(Duration(days: pageIndex * 7));
    
    return List.generate(7, (index) => startOfTargetWeek.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }
  
  String _getFullDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  String _getShortDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getDateContextSuffix() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final difference = selected.difference(today).inDays;

    if (difference == 0) {
      return "today.";
    } else if (difference == 1) {
      return "tomorrow.";
    } else if (difference > 1 && difference < 7) {
      return "on ${_getFullDayName(_selectedDate.weekday)}.";
    } else {
      return "on ${_getMonthName(_selectedDate.month)} ${_selectedDate.day}.";
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showAddTaskModal() {
    bool showError = false;
    DateTime modalDate = _selectedDate;

    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header / Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Task Title Input
                      TextField(
                        controller: _textController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Task title',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        onChanged: (value) {
                          setModalState(() {
                            if (showError) showError = false;
                          });
                        },
                        onSubmitted: (value) {
                          if (value.trim().isEmpty) {
                            setModalState(() {
                              showError = true;
                            });
                            Future.delayed(const Duration(seconds: 2), () {
                              if (context.mounted) {
                                setModalState(() {
                                  showError = false;
                                });
                              }
                            });
                            return;
                          }
                          _addTask(value, date: modalDate);
                        },
                      ).animate()
                       .fadeIn(duration: 400.ms, curve: Curves.easeOutQuart)
                       .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                      
                      const Spacer(),
                      
                      // Chips Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            // Date Chip
                            GestureDetector(
                              onTap: () async {
                                await showCupertinoModalPopup(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Container(
                                      height: 300,
                                      color: const Color(0xFF1E1E1E),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2C2C2C),
                                              border: Border(
                                                bottom: BorderSide(color: Colors.white10),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                CupertinoButton(
                                                  padding: EdgeInsets.zero,
                                                  child: const Text(
                                                    "Done",
                                                    style: TextStyle(
                                                      color: Color(0xFFE57373),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: CupertinoTheme(
                                              data: const CupertinoThemeData(
                                                brightness: Brightness.dark,
                                                textTheme: CupertinoTextThemeData(
                                                  dateTimePickerTextStyle: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                              child: CupertinoDatePicker(
                                                initialDateTime: modalDate,
                                                mode: CupertinoDatePickerMode.date,
                                                minimumDate: DateTime(2000),
                                                maximumDate: DateTime(2100),
                                                onDateTimeChanged: (DateTime newDate) {
                                                  setModalState(() {
                                                    modalDate = newDate;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 18, color: Colors.white70),
                                    const SizedBox(width: 8),
                                    Text(
                                      isSameDay(date: modalDate, other: DateTime.now())
                                          ? "Today"
                                          : "${_getShortDayName(modalDate.weekday)}, ${modalDate.day} ${_getMonthName(modalDate.month)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate(delay: 100.ms)
                             .fadeIn(duration: 400.ms, curve: Curves.easeOutQuart)
                             .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                            

                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Add Button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_textController.text.trim().isEmpty) {
                              setModalState(() {
                                showError = true;
                              });
                              Future.delayed(const Duration(seconds: 2), () {
                                if (context.mounted) {
                                  setModalState(() {
                                    showError = false;
                                  });
                                }
                              });
                            } else {
                              _addTask(_textController.text, date: modalDate);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _textController.text.trim().isEmpty
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFE57373),
                            foregroundColor: _textController.text.trim().isEmpty
                                ? Colors.grey
                                : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            animationDuration: const Duration(milliseconds: 300),
                          ),
                          child: const Text(
                            "Add",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate(delay: 300.ms)
                       .fadeIn(duration: 400.ms, curve: Curves.easeOutQuart)
                       .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                    ],
                  ),
                  
                  // Custom Notification Toast
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: showError ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuart,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE57373),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Please enter a task",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double minExtent = 60.0 + 120.0 + MediaQuery.of(context).padding.top;
    final double maxExtent = _expandedHeight - minExtent;

    return Scaffold(
      key: Key(_studentName),
      backgroundColor: const Color(0xFF121212), // Unified Dark Grey Background
      body: CustomScrollView(
        controller: _scrollController,
        physics: SnapScrollPhysics(snapTarget: maxExtent),
        slivers: [
              // Sliver 1: The Header (Tue + Date Strip + Greeting)
              SliverAppBar(
                expandedHeight: _expandedHeight,
                toolbarHeight: 60.0, // Height for the "Tue" Title
                // collapsedHeight removed to let Flutter calculate it (Toolbar + Bottom + TopPadding)
                pinned: true,

                backgroundColor: const Color(0xFF1E1E1E), // Grey when collapsed
                elevation: 0,
                // Title: "Tue"
                title: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildHeaderTitle(),
                ),
                titleSpacing: 0,
                centerTitle: false,
                // Bottom: Date Strip (Pinned with Header)
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(120.0),
                  child: _buildDateStripBottom(),
                ),
                // Flexible Space: Greeting
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _buildGreetingContent(minExtent),
                ),
              ),

              // Sliver 2: The Task List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final currentList = _currentTodoList;
                    final task = currentList[index];
                    final isCompleted = _currentCompletedItems.contains(index);
                    
                    return TaskListItem(
                      key: ValueKey("${_getDateKey(_selectedDate)}_$index"), // Unique key per date/index
                      task: task,
                      index: index,
                      isCompleted: isCompleted,
                      isLast: index == currentList.length - 1,
                      onToggle: () => _toggleTask(index),
                      onRemove: () => _removeTask(index),
                      delay: (index * 100).ms,
                    );
                  },
                  childCount: _currentTodoList.length,
                ),
              ),
              
              // Spacer to ensure FAB doesn't cover last item, with Sheet Color
              SliverToBoxAdapter(
                child: Container(
                  height: 100,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              // Fill remaining space with Sheet Color
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddTaskModal,
          backgroundColor: const Color(0xFF2C2C2C),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showCalendarPicker() {
    DateTime tempDate = _selectedDate;
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C2C),
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text("Done", style: TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempDate;
                          final now = DateTime.now();
                          final currentMonday = now.subtract(Duration(days: now.weekday - 1));
                          final targetMonday = tempDate.subtract(Duration(days: tempDate.weekday - 1));
                          final weekDiff = targetMonday.difference(currentMonday).inDays ~/ 7;
                          _pageController.jumpToPage(_initialPage + weekDiff);
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.dark),
                  child: CupertinoDatePicker(
                    initialDateTime: _selectedDate,
                    mode: CupertinoDatePickerMode.date,
                    onDateTimeChanged: (val) => tempDate = val,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuart,
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        ...previousChildren.map((c) => Positioned(left: 0, top: 0, child: c)),
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, -0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _getShortDayName(_selectedDate.weekday),
                    key: ValueKey("day_${_selectedDate.weekday}"),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const Text(
                '.',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE57373),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showCalendarPicker,
                icon: const Icon(LucideIcons.calendar, color: Colors.white54, size: 24),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (Widget child, Animation<double> animation) {
               return FadeTransition(opacity: animation, child: child);
            },
            child: Column(
              key: ValueKey("date_${_selectedDate.day}"),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${_getMonthName(_selectedDate.month)} ${_selectedDate.day}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "${_selectedDate.year}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStripBottom() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark Grey Sheet
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30), // Rounded Top Corners
        ),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 0),
      child: Column(
        children: [
          _buildCalendarStrip(),
          const SizedBox(height: 16),
          // Dotted Line Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildDottedSeparator(),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingContent(double topPadding) {
    final remainingTasks = _currentTodoList.length - _currentCompletedItems.length;
    return Container(
      color: const Color(0xFF121212), // Flat Dark Grey
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: topPadding + 20.0, // Add minExtent + spacing
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Adjust spacing
          Text(
            _greeting,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate()
           .fadeIn(duration: 800.ms, curve: Curves.easeOutQuart)
           .blurXY(begin: 10, end: 0, duration: 800.ms, curve: Curves.easeOutQuart)
           .scaleXY(begin: 0.95, end: 1, duration: 800.ms, curve: Curves.easeOutQuart)
           .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutQuart),
          
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "You have",
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    _greetingIcon,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeOutQuart,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final double blur = (1.0 - animation.value) * 4.0;
                          return ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                            child: FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.5),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    child: remainingTasks == 0
                        ? Text(
                            " nothing",
                            key: const ValueKey("nothing"),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          )
                        : Row(
                            key: const ValueKey("habits_row"),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                                  return Stack(
                                    alignment: Alignment.centerLeft,
                                    children: <Widget>[
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  );
                                },
                                switchInCurve: Curves.easeOutQuart,
                                switchOutCurve: Curves.easeOutQuart,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      final double blur = (1.0 - animation.value) * 4.0;
                                      return ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.0, 0.5),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                      );
                                    },
                                    child: child,
                                  );
                                },
                                child: Text(
                                  " $remainingTasks",
                                  key: ValueKey(remainingTasks),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const Text(
                                " tasks",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms)
           .fadeIn(duration: 800.ms, curve: Curves.easeOutQuart)
           .blurXY(begin: 10, end: 0, duration: 800.ms, curve: Curves.easeOutQuart)
           .scaleXY(begin: 0.95, end: 1, duration: 800.ms, curve: Curves.easeOutQuart)
           .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutQuart),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "left ",
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeOutQuart,
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          ...previousChildren.map((c) => Positioned(left: 0, top: 0, child: c)),
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final double blur = (1.0 - animation.value) * 4.0;
                          return ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    child: Text(
                      _getDateContextSuffix(),
                      key: ValueKey(_getDateContextSuffix()),
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms)
           .fadeIn(duration: 800.ms, curve: Curves.easeOutQuart)
           .blurXY(begin: 10, end: 0, duration: 800.ms, curve: Curves.easeOutQuart)
           .scaleXY(begin: 0.95, end: 1, duration: 800.ms, curve: Curves.easeOutQuart)
           .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutQuart),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return SizedBox(
      height: 85,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          // Optional: Update state if needed
        },
        itemBuilder: (context, index) {
          final weekDays = _generateWeekDays(index - _initialPage);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((date) {
                final isSelected = isSameDay(date: date, other: _selectedDate);
                final isToday = isSameDay(date: date, other: DateTime.now());
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_scrollController.hasClients && _scrollController.offset > 0) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutQuart,
                        ).then((_) {
                          setState(() {
                            _selectedDate = date;
                          });
                        });
                      } else {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: _buildCalendarItem(
                      _getDayName(date.weekday),
                      date.day.toString(),
                      isSelected,
                      isToday,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarItem(String day, String date, bool isSelected, bool isToday) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2C2C2C) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.white10) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isToday)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFE57373),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            date,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            day,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFFE57373) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedSeparator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            );
          }),
        );
      },
    );
  }
}

class DashedRoundedSquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(8)));

    final Path dashPath = Path();
    final double dashWidth = 4;
    final double dashSpace = 4;
    double distance = 0;

    for (final ui.PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const double dashWidth = 2;
    const double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TaskListItem extends StatefulWidget {
  final String task;
  final int index;
  final bool isCompleted;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final Duration delay;

  const TaskListItem({
    super.key,
    required this.task,
    required this.index,
    required this.isCompleted,
    required this.isLast,
    required this.onToggle,
    required this.onRemove,
    required this.delay,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark Grey Sheet (Continuous)
      ),
      child: Column(
        children: [
          Dismissible(
            key: Key('${widget.task}_${widget.index}'),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) => widget.onRemove(),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutQuart,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: widget.isCompleted
                            ? const Color(0xFFE57373)
                            : Colors.transparent,
                        border: widget.isCompleted
                            ? Border.all(
                                color: const Color(0xFFE57373),
                                width: 2,
                              )
                            : null,
                      ),
                      child: widget.isCompleted
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.black)
                          : CustomPaint(painter: DashedRoundedSquarePainter()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutQuart,
                      style: TextStyle(
                        fontSize: 18,
                        color: widget.isCompleted
                            ? Colors.grey[700]
                            : Colors.white,
                        decoration: widget.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.grey[700],
                        fontFamily: 'Roboto',
                      ),
                      child: Text(widget.task),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Dotted Divider
          if (!widget.isLast)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: CustomPaint(
                size: const Size(double.infinity, 1),
                painter: DottedLinePainter(),
              ),
            ),
        ],
      ),
    ).animate(controller: _controller, autoPlay: false)
     .fadeIn(duration: 800.ms, curve: Curves.easeOutQuart)
     .blurXY(begin: 10, end: 0, duration: 800.ms, curve: Curves.easeOutQuart)
     .scaleXY(begin: 0.95, end: 1, duration: 800.ms, curve: Curves.easeOutQuart)
     .slideY(
        begin: 0.3,
        end: 0,
        duration: 800.ms,
        curve: Curves.easeOutQuart
     );
  }
}


class SnapScrollPhysics extends ClampingScrollPhysics {
  final double snapTarget;

  const SnapScrollPhysics({
    super.parent,
    required this.snapTarget,
  });

  @override
  SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnapScrollPhysics(
      parent: buildParent(ancestor),
      snapTarget: snapTarget,
    );
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (position.pixels < snapTarget && position.pixels > 0) {
      double target;
      if (velocity > 0) {
        target = snapTarget;
      } else if (velocity < 0) {
        target = 0.0;
      } else {
        target = position.pixels > snapTarget / 2 ? snapTarget : 0.0;
      }
      
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
