import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/system.dart';
import '../models/goal.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';

class AddSystemScreen extends StatefulWidget {
  final System? systemToEdit;
  
  const AddSystemScreen({super.key, this.systemToEdit});

  @override
  State<AddSystemScreen> createState() => _AddSystemScreenState();
}

class _AddSystemScreenState extends State<AddSystemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'e.g., Morning Routine, Health & Fitness');
  final _descriptionController = TextEditingController(text: 'Describe what this system is for and your goals');
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();
  bool _isLoading = false;
  String _selectedCategory = 'Health & Fitness';
  String? _selectedGoalId;
  List<Goal> _goals = [];

  final List<String> _categories = [
    'Health & Fitness',
    'Productivity',
    'Learning',
    'Mindfulness',
    'Relationships',
    'Career',
    'Finance',
    'Hobbies',
    'Home & Organization',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    
    // If editing an existing system, populate the form
    if (widget.systemToEdit != null) {
      _nameController.text = widget.systemToEdit!.name;
      _descriptionController.text = widget.systemToEdit!.description;
      _selectedCategory = widget.systemToEdit!.category;
      // Don't set _selectedGoalId here - it will be set in _loadGoals after goals are loaded
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final goals = await _dataService.getGoals();
    setState(() {
      _goals = goals;
      
      // If editing an existing system, set the selected goal ID after goals are loaded
      if (widget.systemToEdit != null && widget.systemToEdit!.goalId != null) {
        // Check if the goal still exists in the goals list
        final goalExists = goals.any((goal) => goal.id == widget.systemToEdit!.goalId);
        if (goalExists) {
          _selectedGoalId = widget.systemToEdit!.goalId;
        } else {
          // Goal was deleted, so clear the selection
          _selectedGoalId = null;
        }
      }
    });
  }

  Future<void> _saveSystem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final system = System(
        id: widget.systemToEdit?.id ?? _dataService.generateId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        goalId: _selectedGoalId,
        createdAt: widget.systemToEdit?.createdAt ?? DateTime.now(),
        habits: widget.systemToEdit?.habits ?? [],
      );

      await _dataService.saveSystem(system);
      
      // Award XP for creating system (only if it's a new system)
      if (widget.systemToEdit == null) {
        await _gamificationService.createSystem();
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
                              widget.systemToEdit == null 
                                  ? 'System created successfully!' 
                                  : 'System updated successfully!',
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
            content: Text('Error creating system: $e'),
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
          widget.systemToEdit == null ? 'Create System' : 'Edit System',
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Iconsax.add_square,
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
                              'Create New System',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Organize your habits into focused systems',
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
                  'System Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // System Name Field
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
                      labelText: 'System Name',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _nameController.text == 'e.g., Morning Routine, Health & Fitness'
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onTap: () {
                      if (_nameController.text == 'e.g., Morning Routine, Health & Fitness') {
                        _nameController.clear();
                        setState(() {});
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value == 'e.g., Morning Routine, Health & Fitness') {
                        return 'Please enter a system name';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Category Field
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
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Goal Selection Field
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
                  child: DropdownButtonFormField<String?>(
                    value: _selectedGoalId,
                    decoration: InputDecoration(
                      labelText: 'Connected Goal (Optional)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Goal Selected'),
                      ),
                      ..._goals.map((Goal goal) {
                        return DropdownMenuItem<String?>(
                          value: goal.id,
                          child: Text(
                            goal.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGoalId = newValue;
                      });
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
                      color: _descriptionController.text == 'Describe what this system is for and your goals'
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 4,
                    onTap: () {
                      if (_descriptionController.text == 'Describe what this system is for and your goals') {
                        _descriptionController.clear();
                        setState(() {});
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value == 'Describe what this system is for and your goals') {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSystem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                              const Icon(Iconsax.add_square, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.systemToEdit == null ? 'Create System' : 'Update System',
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
