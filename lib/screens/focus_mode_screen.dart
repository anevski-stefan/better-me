import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  Timer? _timer;
  int _timeRemaining = 25 * 60; // 25 minutes in seconds
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;
  int _currentSession = 1;
  

  // Pomodoro settings (now customizable)
  int _workDuration = 25; // minutes
  int _shortBreakDuration = 5; // minutes
  int _longBreakDuration = 15; // minutes
  final int _sessionsBeforeLongBreak = 4;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _resumeTimer();
    }
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _timeRemaining = _isBreak ? _shortBreakDuration * 60 : _workDuration * 60;
    });
    
    _timer?.cancel();
  }

  void _completeSession() {
    _timer?.cancel();
    
    if (!_isBreak) {
      // Work session completed
      setState(() {
        _completedPomodoros++;
        _currentSession++;
        _isBreak = true;
        _timeRemaining = _completedPomodoros % _sessionsBeforeLongBreak == 0 
            ? _longBreakDuration * 60 
            : _shortBreakDuration * 60;
      });
      
      _showSessionCompleteDialog('Work session completed! Time for a break.');
    } else {
      // Break completed
      setState(() {
        _isBreak = false;
        _timeRemaining = _workDuration * 60;
      });
      
      _showSessionCompleteDialog('Break time is over! Ready for another work session?');
    }
  }

  void _showSessionCompleteDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('Start Next'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    int tempWorkDuration = _workDuration;
    int tempShortBreak = _shortBreakDuration;
    int tempLongBreak = _longBreakDuration;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Timer Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDurationSlider(
                'Work Duration',
                tempWorkDuration,
                5,
                60,
                (value) => setState(() => tempWorkDuration = value),
              ),
              const SizedBox(height: 20),
              _buildDurationSlider(
                'Short Break',
                tempShortBreak,
                1,
                30,
                (value) => setState(() => tempShortBreak = value),
              ),
              const SizedBox(height: 20),
              _buildDurationSlider(
                'Long Break',
                tempLongBreak,
                5,
                60,
                (value) => setState(() => tempLongBreak = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _workDuration = tempWorkDuration;
                  _shortBreakDuration = tempShortBreak;
                  _longBreakDuration = tempLongBreak;
                  _resetTimer();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSlider(
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$value min',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    final totalTime = _isBreak 
        ? (_completedPomodoros % _sessionsBeforeLongBreak == 0 
            ? _longBreakDuration * 60 
            : _shortBreakDuration * 60)
        : _workDuration * 60;
    return 1.0 - (_timeRemaining / totalTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Focus Mode',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Iconsax.setting_2),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Focus Mode Info'),
                  content: const Text(
                    'Pomodoro Technique:\n\n'
                    '• 25 minutes focused work\n'
                    '• 5 minute short break\n'
                    '• 15 minute long break (every 4 sessions)\n\n'
                    'Stay focused and take breaks to maintain productivity!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Iconsax.info_circle),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progress Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Iconsax.timer_1,
                      label: 'Completed',
                      value: '$_completedPomodoros',
                      color: Colors.green,
                    ),
                    _buildStatItem(
                      context,
                      icon: Iconsax.clock,
                      label: 'Session',
                      value: '$_currentSession',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _buildStatItem(
                      context,
                      icon: _isBreak ? Iconsax.coffee : Iconsax.briefcase,
                      label: _isBreak ? 'Break' : 'Work',
                      value: _isBreak ? 'Rest' : 'Focus',
                      color: _isBreak ? Colors.orange : Colors.blue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Timer Circle
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    
                    // Progress circle
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: _getProgress(),
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isBreak ? Colors.orange : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    
                    // Time display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_timeRemaining),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _isBreak ? Colors.orange : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isBreak ? 'Break Time' : 'Focus Time',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    context,
                    icon: Iconsax.refresh,
                    label: 'Reset',
                    onTap: _resetTimer,
                    color: Colors.grey,
                  ),
                  _buildControlButton(
                    context,
                    icon: _isRunning ? Iconsax.pause : Iconsax.play,
                    label: _isRunning ? 'Pause' : 'Start',
                    onTap: _startTimer,
                    color: _isRunning ? Colors.orange : Colors.green,
                    isPrimary: true,
                  ),
                  _buildControlButton(
                    context,
                    icon: Iconsax.forward,
                    label: 'Skip',
                    onTap: _completeSession,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Session Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next: ${_isBreak ? "Work Session" : "Break"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_completedPomodoros % _sessionsBeforeLongBreak == 0 ? "Long" : "Short"} Break',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPrimary ? 24 : 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
