# DayGlow

A beautiful iOS app for intentional daily planning and gratitude tracking. DayGlow helps you schedule your day, track meaningful moments, and build positive habits through daily highlights and streaks.

## Features

### Calendar & Event Planning
- **Monthly Calendar View**: Visual overview of your days with color-coded events
- **Event Scheduling**: Create and manage events with customizable times
- **Conflict Detection**: Automatic detection and warnings for overlapping events
- **Flexible Events**: Mark events as flexible for easier rescheduling
- **Event Types**: Categorize events (work, personal, social, deep work, etc.)

### Daily Highlights
- **Gratitude Journaling**: Capture what made each day special
- **Mood Tracking**: Associate emojis with your highlights
- **Star Badges**: Visual indicators on calendar days with highlights
- **Highlight Prompts**: Thoughtful prompts like "What made you smile today?"

### Streak System
- **Current Streak**: Track consecutive days with highlights
- **Longest Streak**: Remember your best performance
- **Progress Encouragement**: Motivational messages based on your streak
- **Visual Indicators**: Fire emojis that grow as your streak builds
  - 0 days: 💫 "Start your streak today!"
  - 1-2 days: ✨ "Great start!"
  - 3-6 days: ⭐️ "You're on a roll!"
  - 7-13 days: 🔥 "Amazing!"
  - 14-29 days: 🔥🔥 "Incredible!"
  - 30+ days: 🔥🔥🔥 "You're a highlight champion!"

### Templates
Quick-start your day with pre-built activity templates:

- **Main Character Solo Date**: Self-care and personal time
- **Reset & Glow-Up Clean**: Cleaning and organizing day
- **Admin Day**: Tackle administrative tasks
- **Deep Work Block**: Focused, distraction-free work sessions
- **Social Connection Time**: Quality time with friends and family

Each template includes:
- Suggested duration
- Activity checklist
- Color coding
- One-tap event creation

### Highlights Recap
- **Statistics Dashboard**: View current streak, total days, and best streak
- **Highlights Feed**: Review all your daily highlights in chronological order
- **Mood Timeline**: See emotional patterns through emoji tracking
- **Empty State Guidance**: Helpful prompts when getting started

## Technical Stack

- **Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Minimum iOS**: iOS 17.0+
- **Architecture**: MVVM with feature-based organization

## Project Structure

```
DayGlow/
├── DayGlow/
│   ├── DayGlowApp.swift           # App entry point
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Event.swift        # Event data model
│   │   │   ├── DayEntry.swift     # Daily highlight model
│   │   │   ├── Template.swift     # Activity template model
│   │   │   └── ModelContainer+Extension.swift
│   │   ├── Services/
│   │   │   ├── ConflictDetector.swift    # Event overlap detection
│   │   │   └── HighlightService.swift    # Streak calculations
│   │   └── Utilities/
│   │       ├── DateExtensions.swift
│   │       └── Theme.swift               # Design system
│   ├── Features/
│   │   ├── Calendar/
│   │   │   ├── ViewModels/
│   │   │   │   └── CalendarViewModel.swift
│   │   │   └── Views/
│   │   │       ├── HomeCalendarView.swift
│   │   │       ├── MonthGridView.swift
│   │   │       ├── DayCell.swift
│   │   │       └── CalendarHeaderView.swift
│   │   ├── DayDetail/
│   │   │   └── Views/
│   │   │       ├── DayDetailView.swift
│   │   │       ├── DayScheduleView.swift
│   │   │       └── HighlightCardView.swift
│   │   ├── Events/
│   │   │   ├── ViewModels/
│   │   │   │   └── EventFormViewModel.swift
│   │   │   └── Views/
│   │   │       ├── AddEditEventView.swift
│   │   │       └── ConflictWarningView.swift
│   │   └── Templates/
│   │       └── Views/
│   │           ├── TemplatesView.swift
│   │           ├── TemplateCardView.swift
│   │           └── TemplateCustomizeView.swift
│   └── Components/
│       ├── Cards/
│       │   └── EventCard.swift
│       ├── Forms/
│       │   └── EmojiPicker.swift
│       └── StreakIndicator.swift
├── DayGlowTests/
└── DayGlowUITests/
```

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- macOS Sonoma or later

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/DayGlow.git
cd DayGlow
```

2. Open the project in Xcode:
```bash
open DayGlow.xcodeproj
```

3. Select your target device or simulator

4. Build and run (⌘R)

## Usage

### Adding Your First Event

1. Open the app and view the calendar
2. Tap on any date
3. Tap the "+" button in the top-right corner
4. Fill in event details:
   - Title
   - Start and end time
   - Optional: location, notes, event type
5. Tap "Save Event"

### Creating a Daily Highlight

1. Tap on a date in the calendar
2. Scroll to the "Today's Highlight" card
3. Tap to expand the editing interface
4. Write what made your day special
5. (Optional) Select a mood emoji
6. Tap "Save Highlight"

### Using Templates

1. Tap on a date
2. Tap the "+" button
3. Select "Use Template"
4. Choose a template (e.g., "Deep Work Block")
5. Customize the time if needed
6. Tap "Create Event"

### Tracking Your Streak

- Navigate to the "Highlights" tab
- View your current streak, total highlight days, and best streak
- Get encouraged by progress messages
- Scroll down to see all your past highlights

## Design Philosophy

DayGlow is built around three core principles:

1. **Intentionality**: Plan your days with purpose using templates and thoughtful scheduling
2. **Gratitude**: Reflect daily on positive moments through highlights
3. **Consistency**: Build habits through streak tracking and gentle encouragement

## Development Status

This is an MVP (Minimum Viable Product) with core features implemented:
- ✅ Event creation and management
- ✅ Conflict detection
- ✅ Daily highlight system
- ✅ Streak tracking
- ✅ Activity templates
- ✅ Highlights recap view

### Future Enhancements

Potential features for future versions:
- Photo attachments for highlights
- Highlight tags/categories
- Export highlights to PDF
- Widget support
- iCloud sync
- Sharing highlights
- Voice memos
- Apple Watch companion app

## Contributing

This is currently a personal project. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is available under the MIT License. See LICENSE file for details.

## Acknowledgments

- Built with SwiftUI and SwiftData
- Inspired by intentional living and gratitude practices
- Design influenced by modern iOS design patterns

## Contact

For questions or feedback, please open an issue on GitHub.

---

Made with ❤️ using SwiftUI
