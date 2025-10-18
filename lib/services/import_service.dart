import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'data_service.dart';
import 'export_service.dart';
import '../models/system.dart';
import '../models/goal.dart';
import '../models/journal_entry.dart';

class ImportService {
  final DataService _dataService;
  final ExportService _exportService;

  ImportService({DataService? dataService, ExportService? exportService}) 
      : _dataService = dataService ?? DataService(),
        _exportService = exportService ?? ExportService();

  /// Import data from a file picker result
  Future<ImportResult> importDataFromFile() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: 'No file selected',
        );
      }

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return await _importFromJsonData(jsonData);
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to import data: $e',
      );
    }
  }

  /// Import data from JSON string
  Future<ImportResult> importDataFromString(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return await _importFromJsonData(jsonData);
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to parse JSON data: $e',
      );
    }
  }

  /// Import data from JSON data map
  Future<ImportResult> _importFromJsonData(Map<String, dynamic> jsonData) async {
    try {
      // Validate data structure
      if (!_exportService.validateExportData(jsonData)) {
        return ImportResult(
          success: false,
          message: 'Invalid data format. Please ensure this is a valid Better Me export file.',
        );
      }

      final appData = jsonData['data'] as Map<String, dynamic>;
      final systemsData = appData['systems'] as List<dynamic>? ?? [];
      final goalsData = appData['goals'] as List<dynamic>? ?? [];
      final journalEntriesData = appData['journalEntries'] as List<dynamic>? ?? [];

      int importedSystems = 0;
      int importedGoals = 0;
      int importedJournalEntries = 0;
      int importedHabits = 0;

      // Import systems
      for (final systemJson in systemsData) {
        try {
          final system = System.fromJson(systemJson as Map<String, dynamic>);
          await _dataService.saveSystem(system);
          importedSystems++;
          importedHabits += system.habits.length;
        } catch (e) {
          // Continue with other systems even if one fails
          // Log error but continue processing
        }
      }

      // Import goals
      for (final goalJson in goalsData) {
        try {
          final goal = Goal.fromJson(goalJson as Map<String, dynamic>);
          await _dataService.addGoal(goal);
          importedGoals++;
        } catch (e) {
          // Continue with other goals even if one fails
          // Log error but continue processing
        }
      }

      // Import journal entries
      for (final entryJson in journalEntriesData) {
        try {
          final entry = JournalEntry.fromJson(entryJson as Map<String, dynamic>);
          await _dataService.addJournalEntry(entry);
          importedJournalEntries++;
        } catch (e) {
          // Continue with other entries even if one fails
          // Log error but continue processing
        }
      }

      return ImportResult(
        success: true,
        message: 'Successfully imported $importedSystems systems, $importedGoals goals, $importedJournalEntries journal entries, and $importedHabits habits.',
        importedSystems: importedSystems,
        importedGoals: importedGoals,
        importedJournalEntries: importedJournalEntries,
        importedHabits: importedHabits,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to import data: $e',
      );
    }
  }

  /// Import data with merge option (keep existing data)
  Future<ImportResult> importDataWithMerge() async {
    return await importDataFromFile();
  }

  /// Import data with replace option (clear existing data first)
  Future<ImportResult> importDataWithReplace() async {
    try {
      // Clear existing data first
      final systems = await _dataService.getSystems();
      for (final system in systems) {
        await _dataService.deleteSystem(system.id);
      }

      final goals = await _dataService.getGoals();
      for (final goal in goals) {
        await _dataService.deleteGoal(goal.id);
      }

      final journalEntries = await _dataService.getJournalEntries();
      for (final entry in journalEntries) {
        await _dataService.deleteJournalEntry(entry.id);
      }

      // Import new data
      return await importDataFromFile();
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to replace data: $e',
      );
    }
  }

  /// Validate import file without importing
  Future<ValidationResult> validateImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ValidationResult(
          isValid: false,
          message: 'No file selected',
        );
      }

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!_exportService.validateExportData(jsonData)) {
        return ValidationResult(
          isValid: false,
          message: 'Invalid data format. Please ensure this is a valid Better Me export file.',
        );
      }

      final appData = jsonData['data'] as Map<String, dynamic>;
      final systemsData = appData['systems'] as List<dynamic>? ?? [];
      final goalsData = appData['goals'] as List<dynamic>? ?? [];
      final journalEntriesData = appData['journalEntries'] as List<dynamic>? ?? [];

      int totalHabits = 0;
      for (final systemJson in systemsData) {
        final system = System.fromJson(systemJson as Map<String, dynamic>);
        totalHabits += system.habits.length;
      }

      return ValidationResult(
        isValid: true,
        message: 'File is valid and ready to import',
        systemsCount: systemsData.length,
        goalsCount: goalsData.length,
        journalEntriesCount: journalEntriesData.length,
        habitsCount: totalHabits,
        exportDate: jsonData['exportDate'] as String?,
        appName: jsonData['appName'] as String?,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        message: 'Failed to validate file: $e',
      );
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int? importedSystems;
  final int? importedGoals;
  final int? importedJournalEntries;
  final int? importedHabits;

  ImportResult({
    required this.success,
    required this.message,
    this.importedSystems,
    this.importedGoals,
    this.importedJournalEntries,
    this.importedHabits,
  });
}

class ValidationResult {
  final bool isValid;
  final String message;
  final int? systemsCount;
  final int? goalsCount;
  final int? journalEntriesCount;
  final int? habitsCount;
  final String? exportDate;
  final String? appName;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.systemsCount,
    this.goalsCount,
    this.journalEntriesCount,
    this.habitsCount,
    this.exportDate,
    this.appName,
  });
}
