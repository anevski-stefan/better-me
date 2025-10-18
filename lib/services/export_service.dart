import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'data_service.dart';

class ExportService {
  final DataService _dataService;

  ExportService({DataService? dataService}) : _dataService = dataService ?? DataService();

  /// Export all app data to a JSON file with user-selected destination
  Future<String?> exportDataWithDestination() async {
    try {
      // Gather all data first
      final systems = await _dataService.getSystems();
      final goals = await _dataService.getGoals();
      final journalEntries = await _dataService.getJournalEntries();
      
      // Create export data structure
      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Better Me',
        'data': {
          'systems': systems.map((s) => s.toJson()).toList(),
          'goals': goals.map((g) => g.toJson()).toList(),
          'journalEntries': journalEntries.map((j) => j.toJson()).toList(),
        },
        'metadata': {
          'totalSystems': systems.length,
          'totalGoals': goals.length,
          'totalJournalEntries': journalEntries.length,
          'totalHabits': systems.fold(0, (sum, system) => sum + system.habits.length),
        }
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Convert string to bytes for mobile platforms
      final bytes = utf8.encode(jsonString);

      // Let user choose where to save the file
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Better Me Data',
        fileName: 'better_me_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (result == null) {
        return null; // User cancelled
      }

      return result;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Export all app data to a JSON file (default location)
  Future<String?> exportData() async {
    try {
      // Gather all data
      final systems = await _dataService.getSystems();
      final goals = await _dataService.getGoals();
      final journalEntries = await _dataService.getJournalEntries();
      
      // Create export data structure
      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Better Me',
        'data': {
          'systems': systems.map((s) => s.toJson()).toList(),
          'goals': goals.map((g) => g.toJson()).toList(),
          'journalEntries': journalEntries.map((j) => j.toJson()).toList(),
        },
        'metadata': {
          'totalSystems': systems.length,
          'totalGoals': goals.length,
          'totalJournalEntries': journalEntries.length,
          'totalHabits': systems.fold(0, (sum, system) => sum + system.habits.length),
        }
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Get downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'better_me_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      // Convert string to bytes and write file
      final bytes = utf8.encode(jsonString);
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Export data to a specific file path
  Future<void> exportDataToFile(String filePath) async {
    try {
      // Gather all data
      final systems = await _dataService.getSystems();
      final goals = await _dataService.getGoals();
      final journalEntries = await _dataService.getJournalEntries();
      
      // Create export data structure
      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Better Me',
        'data': {
          'systems': systems.map((s) => s.toJson()).toList(),
          'goals': goals.map((g) => g.toJson()).toList(),
          'journalEntries': journalEntries.map((j) => j.toJson()).toList(),
        },
        'metadata': {
          'totalSystems': systems.length,
          'totalGoals': goals.length,
          'totalJournalEntries': journalEntries.length,
          'totalHabits': systems.fold(0, (sum, system) => sum + system.habits.length),
        }
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Convert string to bytes and write to specified file
      final bytes = utf8.encode(jsonString);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Get export data as JSON string (for sharing)
  Future<String> getExportDataAsString() async {
    try {
      // Gather all data
      final systems = await _dataService.getSystems();
      final goals = await _dataService.getGoals();
      final journalEntries = await _dataService.getJournalEntries();
      
      // Create export data structure
      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Better Me',
        'data': {
          'systems': systems.map((s) => s.toJson()).toList(),
          'goals': goals.map((g) => g.toJson()).toList(),
          'journalEntries': journalEntries.map((j) => j.toJson()).toList(),
        },
        'metadata': {
          'totalSystems': systems.length,
          'totalGoals': goals.length,
          'totalJournalEntries': journalEntries.length,
          'totalHabits': systems.fold(0, (sum, system) => sum + system.habits.length),
        }
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      throw Exception('Failed to generate export data: $e');
    }
  }

  /// Validate export data structure
  bool validateExportData(Map<String, dynamic> data) {
    try {
      // Check required top-level fields
      if (!data.containsKey('version') || 
          !data.containsKey('exportDate') || 
          !data.containsKey('appName') || 
          !data.containsKey('data')) {
        return false;
      }

      final appData = data['data'] as Map<String, dynamic>?;
      if (appData == null) return false;

      // Check required data sections
      if (!appData.containsKey('systems') || 
          !appData.containsKey('goals') || 
          !appData.containsKey('journalEntries')) {
        return false;
      }

      // Validate systems structure
      final systems = appData['systems'] as List<dynamic>?;
      if (systems != null) {
        for (final system in systems) {
          if (system is! Map<String, dynamic>) return false;
          if (!system.containsKey('id') || !system.containsKey('name')) return false;
        }
      }

      // Validate goals structure
      final goals = appData['goals'] as List<dynamic>?;
      if (goals != null) {
        for (final goal in goals) {
          if (goal is! Map<String, dynamic>) return false;
          if (!goal.containsKey('id') || !goal.containsKey('name')) return false;
        }
      }

      // Validate journal entries structure
      final journalEntries = appData['journalEntries'] as List<dynamic>?;
      if (journalEntries != null) {
        for (final entry in journalEntries) {
          if (entry is! Map<String, dynamic>) return false;
          if (!entry.containsKey('id') || !entry.containsKey('title')) return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
