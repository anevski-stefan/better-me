import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:iconsax/iconsax.dart';
import '../models/habit.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';

class AddHabitScreen extends StatefulWidget {
  final String systemId;
  final Habit? habitToEdit;

  const AddHabitScreen({super.key, required this.systemId, this.habitToEdit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'e.g., Drink 8 glasses of water, Exercise 30 minutes');
  final _descriptionController = TextEditingController(text: 'Describe this habit in more detail and why it matters');
  final DataService _dataService = DataService();
  bool _isLoading = false;
  bool _hasReminder = false;
  TimeOfDay? _reminderTime;
  List<bool> _daySelected = [false, false, false, false, false, false, false];

  final List<String> _dayNames = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];

  @override
  void initState() {
    super.initState();
    
    // If editing an existing habit, populate the form
    if (widget.habitToEdit != null) {
      _nameController.text = widget.habitToEdit!.name;
      _descriptionController.text = widget.habitToEdit!.description;
      _hasReminder = widget.habitToEdit!.hasReminder;
      _reminderTime = widget.habitToEdit!.reminderTime;
      
      // Set the selected days
      if (widget.habitToEdit!.reminderDays != null) {
        for (int day in widget.habitToEdit!.reminderDays!) {
          if (day >= 0 && day < 7) {
            _daySelected[day] = true;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final habit = Habit(
        id: widget.habitToEdit?.id ?? _dataService.generateId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        systemId: widget.systemId,
        createdAt: widget.habitToEdit?.createdAt ?? DateTime.now(),
        hasReminder: _hasReminder,
        reminderTime: _reminderTime,
        reminderDays: _daySelected.asMap().entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
        isCompleted: widget.habitToEdit?.isCompleted ?? false,
        completedAt: widget.habitToEdit?.completedAt,
        completedDates: widget.habitToEdit?.completedDates,
      );

      if (widget.habitToEdit == null) {
        await _dataService.addHabitToSystem(widget.systemId, habit);
      } else {
        await _dataService.updateHabitInSystem(widget.systemId, habit);
      }
      
      // Schedule habit reminder notifications
      if (_hasReminder && _reminderTime != null) {
        final reminderDays = _daySelected.asMap().entries.where((entry) => entry.value).map((entry) => entry.key).toList();
        await NotificationService.scheduleHabitReminders(
          habit.id,
          habit.name,
          _reminderTime!,
          reminderDays,
        );
      } else {
        // Cancel notifications if reminder is disabled
        await NotificationService.cancelHabitReminders(habit.id);
      }

      if (mounted) {
        Navigator.pop(context);
        // Show success message at the very top using Overlay with animation
        final overlay = Overlay.of(context);
        late OverlayEntry overlayEntry;
        final animationController = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: Navigator.of(context),
        );
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        );
        final slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        );
        
        overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) => FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.tick_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.habitToEdit == null 
                                  ? 'Habit added successfully!' 
                                  : 'Habit updated successfully!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        
        overlay.insert(overlayEntry);
        animationController.forward();
        
        // Remove overlay after 3 seconds with fade out animation
        Future.delayed(const Duration(seconds: 2), () {
          animationController.reverse().then((_) {
            overlayEntry.remove();
            animationController.dispose();
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.habitToEdit == null ? 'Add Habit' : 'Edit Habit',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Iconsax.tick_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Habit',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a specific habit to track your progress',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form Fields
                Text(
                  'Habit Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Habit Name Field
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Habit Name',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _nameController.text == 'e.g., Drink 8 glasses of water, Exercise 30 minutes'
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onTap: () {
                      if (_nameController.text == 'e.g., Drink 8 glasses of water, Exercise 30 minutes') {
                        _nameController.clear();
                        setState(() {});
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value == 'e.g., Drink 8 glasses of water, Exercise 30 minutes') {
                        return 'Please enter a habit name';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Description Field
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _descriptionController.text == 'Describe this habit in more detail and why it matters'
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 4,
                    onTap: () {
                      if (_descriptionController.text == 'Describe this habit in more detail and why it matters') {
                        _descriptionController.clear();
                        setState(() {});
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value == 'Describe this habit in more detail and why it matters') {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Reminder Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.notification,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reminder',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Reminder Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Enable reminder',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        value: _hasReminder,
                        onChanged: (value) {
                          setState(() {
                            _hasReminder = value;
                            if (!value) {
                              _reminderTime = null;
                              _daySelected = [false, false, false, false, false, false, false];
                            }
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      
                      if (_hasReminder) ...[
                        const SizedBox(height: 16),
                        
                        // Time Selection
                        InkWell(
                          onTap: _selectTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.clock,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _reminderTime != null
                                      ? _reminderTime!.format(context)
                                      : 'Select time',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: _reminderTime != null
                                        ? Theme.of(context).textTheme.bodyLarge?.color
                                        : Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Iconsax.arrow_down_1,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Days Selection
                        Text(
                          'Repeat on:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(7, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _daySelected[index] = !_daySelected[index];
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _daySelected[index]
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _daySelected[index]
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).dividerColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _dayNames[index],
                                    style: TextStyle(
                                      color: _daySelected[index]
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveHabit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.tick_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.habitToEdit == null ? 'Add Habit' : 'Update Habit',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
