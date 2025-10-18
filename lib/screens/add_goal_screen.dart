import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/goal.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'e.g., Run a Marathon, Learn Spanish');
  final _descriptionController = TextEditingController(text: 'Describe your goal and why it matters to you');
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();
  bool _isLoading = false;
  
  DateTime? _selectedTargetDate;
  bool _hasTargetDate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years from now
    );
    
    if (picked != null && picked != _selectedTargetDate) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final goal = Goal(
        id: _dataService.generateId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        targetDate: _hasTargetDate ? _selectedTargetDate : null,
      );

      await _dataService.addGoal(goal);
      
      // Award XP for creating goal
      await _gamificationService.createGoal();

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
                          const Expanded(
                            child: Text(
                              'Goal created successfully!',
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
            content: Text('Error creating goal: $e'),
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
          'Create Goal',
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
                          Iconsax.flag,
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
                              'Create New Goal',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set a meaningful goal to work towards',
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
                  'Goal Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Goal Name Field
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
                      labelText: 'Goal Name',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _nameController.text == 'e.g., Run a Marathon, Learn Spanish'
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onTap: () {
                      if (_nameController.text == 'e.g., Run a Marathon, Learn Spanish') {
                        _nameController.clear();
                        setState(() {});
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value == 'e.g., Run a Marathon, Learn Spanish') {
                        return 'Please enter a goal name';
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
                      color: _descriptionController.text == 'Describe your goal and why it matters to you'
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 4,
                    onTap: () {
                      if (_descriptionController.text == 'Describe your goal and why it matters to you') {
                        _descriptionController.clear();
                        setState(() {});
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value == 'Describe your goal and why it matters to you') {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Target Date Section
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
                            Iconsax.calendar_1,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target Date',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Target Date Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Set a target date',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        subtitle: Text(_hasTargetDate && _selectedTargetDate != null
                            ? 'Target: ${_formatDate(_selectedTargetDate!)}'
                            : 'No target date set'),
                        value: _hasTargetDate,
                        onChanged: (value) {
                          setState(() {
                            _hasTargetDate = value;
                            if (!value) {
                              _selectedTargetDate = null;
                            }
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      
                      if (_hasTargetDate) ...[
                        const SizedBox(height: 16),
                        
                        // Date Selection
                        InkWell(
                          onTap: _selectDate,
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
                                  Iconsax.calendar_1,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedTargetDate != null
                                      ? _formatDate(_selectedTargetDate!)
                                      : 'Select target date',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: _selectedTargetDate != null
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
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGoal,
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
                              const Icon(Iconsax.flag, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Create Goal',
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
