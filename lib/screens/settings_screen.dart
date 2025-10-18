import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/notification_service.dart';
import '../models/user_profile.dart';
import 'achievements_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();
  late final ExportService _exportService;
  late final ImportService _importService;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _exportService = ExportService(dataService: _dataService);
    _importService = ImportService(dataService: _dataService, exportService: _exportService);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _gamificationService.getProfile();
    setState(() {
      _userProfile = profile;
    });
  }


  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all your systems and habits. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await _dataService.getSystems();
      for (final system in prefs) {
        await _dataService.deleteSystem(system.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final navigator = Navigator.of(context);
    try {
      // Show export options dialog
      final exportOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: const Text('Choose how to export your data:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'choose_location'),
              child: const Text('Choose Save Location'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'default_location'),
              child: const Text('Save to Default Location'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (exportOption == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      String? filePath;
      if (exportOption == 'choose_location') {
        filePath = await _exportService.exportDataWithDestination();
      } else {
        filePath = await _exportService.exportData();
      }
      
      if (mounted) {
        navigator.pop(); // Close loading dialog
        
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data exported successfully to: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export cancelled or failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      // Show import options dialog
      final importOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text('Choose how to import the data:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'merge'),
              child: const Text('Merge with existing data'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'replace'),
              child: const Text('Replace all data'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (importOption == null) return;

      // Show loading dialog
      final navigator = Navigator.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      ImportResult result;
      if (importOption == 'replace') {
        result = await _importService.importDataWithReplace();
      } else {
        result = await _importService.importDataWithMerge();
      }

      if (mounted) {
        navigator.pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        if (result.success) {
          // Refresh user profile after successful import
          await _loadUserProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _validateImportFile() async {
    final navigator = Navigator.of(context);
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final validationResult = await _importService.validateImportFile();

      if (mounted) {
        navigator.pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(validationResult.isValid ? 'File Valid' : 'Invalid File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(validationResult.message),
                if (validationResult.isValid) ...[
                  const SizedBox(height: 16),
                  Text('Systems: ${validationResult.systemsCount ?? 0}'),
                  Text('Goals: ${validationResult.goalsCount ?? 0}'),
                  Text('Journal Entries: ${validationResult.journalEntriesCount ?? 0}'),
                  Text('Habits: ${validationResult.habitsCount ?? 0}'),
                  if (validationResult.exportDate != null)
                    Text('Export Date: ${validationResult.exportDate}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Gamification Widget
            Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                  children: [
                    // Level Badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          '${_userProfile?.level ?? 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // XP Progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${_userProfile?.level ?? 1}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _userProfile?.levelProgress ?? 0.0,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_userProfile?.experiencePoints ?? 0} XP • ${_userProfile?.xpForNextLevel ?? 100} to next level',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Streak
                    Column(
                      children: [
                        Text(
                          '${_userProfile?.streak ?? 0}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Streak',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Motivational Quotes Section
            Text(
              'Daily Motivation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
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
              child: Column(
                children: [
                  // Enable/Disable Quotes
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.quote_up,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    title: const Text('Daily Motivational Quotes'),
                    subtitle: const Text('Receive inspiring quotes every day'),
                    trailing: FutureBuilder<bool>(
                      future: NotificationService.areQuotesEnabled(),
                      builder: (context, snapshot) {
                        return Switch(
                          value: snapshot.data ?? false,
                          onChanged: (value) async {
                            await NotificationService.setQuotesEnabled(value);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // Set Quote Time
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.clock,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: const Text('Quote Time'),
                    subtitle: const Text('Set when to receive daily quotes'),
                    trailing: FutureBuilder<TimeOfDay?>(
                      future: NotificationService.getQuotesTime(),
                      builder: (context, snapshot) {
                        final time = snapshot.data;
                        return Text(
                          time != null 
                            ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                            : 'Not set',
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      },
                    ),
                    onTap: () => _showTimePicker(),
                  ),
                  const Divider(height: 1),
                  // Test Notification
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.notification,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    title: const Text('Test Notification'),
                    subtitle: const Text('Send a test quote notification'),
                    onTap: () async {
                      await NotificationService.sendTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievements Section
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
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
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.crown_1,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                title: const Text('View Achievements'),
                subtitle: const Text('See all your badges and progress'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AchievementsScreen(key: ValueKey('achievements')),
                    ),
                  );
                },
                trailing: const Icon(Iconsax.arrow_right_3),
              ),
            ),

            const SizedBox(height: 24),

            // Data Management Section
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
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
              child: Column(
                children: [
                  // Export Data
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.export_1,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    title: const Text('Export Data'),
                    subtitle: const Text('Save all your data to a file (choose location)'),
                    onTap: _exportData,
                  ),
                  const Divider(height: 1),
                  // Import Data
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.import_1,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: const Text('Import Data'),
                    subtitle: const Text('Load data from a backup file'),
                    onTap: _importData,
                  ),
                  const Divider(height: 1),
                  // Validate Import File
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.document_text,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: const Text('Validate Import File'),
                    subtitle: const Text('Check if a file is valid before importing'),
                    onTap: _validateImportFile,
                  ),
                  const Divider(height: 1),
                  // Clear All Data
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.trash,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: const Text('Clear All Data'),
                    subtitle: const Text('Delete all systems and habits'),
                    onTap: _clearAllData,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About Section
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Better Habits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Better Me helps you create and maintain systems for personal improvement. Track your habits, build consistency, and achieve your goals.',
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
    );
  }

  /// Show time picker for setting quote notification time
  Future<void> _showTimePicker() async {
    final currentTime = await NotificationService.getQuotesTime();
    final initialTime = currentTime ?? const TimeOfDay(hour: 9, minute: 0);
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (pickedTime != null) {
      await NotificationService.setQuotesTime(pickedTime);
      setState(() {});
    }
  }
}
