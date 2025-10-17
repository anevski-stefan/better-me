# Better Me

A self-improvement Flutter application for tracking habits and systems. This app helps you organize your personal development by creating systems that contain multiple habits.

## Features

- **Systems Management**: Create and manage different improvement systems (e.g., "Morning Routine", "Health & Fitness", "Learning")
- **Habit Tracking**: Add habits to each system and track your progress
- **Minimalistic Design**: Clean, simple interface focused on productivity
- **Local Storage**: All data is stored locally using SharedPreferences
- **Modular Architecture**: Well-organized code structure with separate models, services, and screens

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── habit.dart           # Habit model
│   └── system.dart          # System model
├── services/                 # Business logic
│   └── data_service.dart    # Data persistence service
└── screens/                  # UI screens
    ├── home_screen.dart     # Main screen with systems list
    ├── system_detail_screen.dart  # System details and habits
    ├── add_system_screen.dart     # Create new system
    └── add_habit_screen.dart      # Add habit to system
```

## Getting Started

1. Make sure you have Flutter installed on your system
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Usage

1. **Create Systems**: Start by creating systems that represent different areas of improvement
2. **Add Habits**: Within each system, add specific habits you want to track
3. **Track Progress**: Check off habits as you complete them
4. **Stay Organized**: Keep your self-improvement journey structured and manageable

## Dependencies

- `shared_preferences`: For local data storage
- `uuid`: For generating unique IDs
- `flutter`: The Flutter framework

## Architecture

The app follows a clean architecture pattern with:
- **Models**: Data structures for System and Habit
- **Services**: Business logic and data persistence
- **Screens**: UI components and user interactions
- **Separation of Concerns**: Each component has a single responsibility