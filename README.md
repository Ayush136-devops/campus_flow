# 🎓 Campus Flow
### Intelligent Campus Navigation & Room Management System

> Real-time classroom availability for students and faculty at VIT Pune — no more wandering between buildings looking for an empty room.

---

## About

Campus Flow is a mobile application built to replace manual room-tracking systems at large educational institutions. It gives students and faculty instant, real-time visibility into classroom and lecture hall availability across all four buildings on campus.

Built with **Flutter** on the frontend and **Supabase (PostgreSQL)** as the backend, the app supports role-based access, live schedule overrides, QR code navigation, and an intelligent room search — all wrapped in a clean, VIT-branded UI.

---

## Features

### Role-Based Authentication
- Official `@vit.edu` emails enforced via RegEx matching
- **Students** — view room statuses and search for empty rooms
- **Teachers** — full override access to schedule or cancel lectures in real-time

### QR Code Navigation
- Scan QR codes at building entrances or floor lobbies
- Instantly jump to the correct Room List — no manual searching needed

### Intelligent Room Status Engine
- Operates within a **10-hour college window** (8:00 AM – 6:00 PM)
- Dynamically checks system time against the stored timetable

| Status | Meaning |
|---|---|
| 🟢 Green | Room is **Empty** or lecture is **CANCELLED** |
| 🔴 Red | Room is **Occupied** by a scheduled subject |
| 🔵 Blue-Grey | College is **Closed** (outside operating hours) |

### Professor Override & Conflict Management
- **Schedule**: Claim an empty room with name + subject in the live view
- **Cancel**: Cancel your own lecture with one tap
- **Conflict Prevention**: Locked controls if a room is already reserved by another faculty member

### Intelligent Empty Room Finder
- Filter across all buildings and floors for rooms available **right now**
- Partial `RoomID` search supported via `ilike` queries

---

## Architecture

### Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| QR Scanning | `mobile_scanner` |
| Animations | `animations` (Material Motion) |
| Target Platform | Android (Moto G73) / iOS |

### Project Structure

```
lib/
├── main.dart                  # App entry point, Supabase init, routing
├── login_view.dart            # Auth flow, role detection via RegEx
├── campus_home.dart           # Dashboard — building grid + QR scanner
├── building_floors_view.dart  # Floor selection UI
├── room_list_view.dart        # Core logic engine — live data merging
└── search_view.dart           # Real-time empty room search
assets/
└── logo.png
```

### File Breakdown

- **`main.dart`** — Initializes the Supabase client, sets up Material 3 theming (`Deep Blue #1E3A8A`), and handles session persistence routing.
- **`login_view.dart`** — Implements a _Sign-In first, then Sign-Up_ flow to avoid 422 errors. Detects student vs. teacher role using: `r'[a-zA-Z0-9._%+-]+[0-9]{2,}@vit\.edu'`
- **`campus_home.dart`** — Building grid (`GridView`), QR code scanner integration, and `OpenContainer` transitions.
- **`room_list_view.dart`** — The core engine. Runs a **Triple-Future** check fetching the static timetable, active overrides for the current date, and the user's role — then merges them into a live view.
- **`search_view.dart`** — Real-time room queries with a `testHour` variable included for demo/testing across different time states.

---

## 🗄️ Database Schema (Supabase)

### `timetables`
| Column | Description |
|---|---|
| `RoomID` | Primary identifier (e.g., 101, 202) |
| `Building` | Building number (1–4) |
| `Floor` | Floor number |
| `[Day]_[HH:MM]` | 50+ columns covering every hour (08:00–18:00) for each day |

### `overrides`
| Column | Description |
|---|---|
| `room_id` | Foreign key → `timetables` |
| `override_date` | Specific date the change applies |
| `override_hour` | Specific time slot being modified |
| `status` | `RESERVED` or `CANCELLED` |
| `teacher_name` | For transparency and accountability |

### `profiles`
| Column | Description |
|---|---|
| `id` | Linked to Supabase Auth UID |
| `role` | `student` or `teacher` |

> Conflicts in `overrides` are handled via a composite key on `(room_id, date, hour)` using Supabase's `upsert` method.

---

## Dependencies

```yaml
dependencies:
  supabase_flutter:       # Real-time DB + auth
  mobile_scanner:         # QR code scanning
  animations:             # Material Motion (Container Transform)
  cupertino_icons:        # iOS-style icons

dev_dependencies:
  flutter_launcher_icons: # Auto-generates branded app icons
```

---

## Getting Started

### Prerequisites
- Flutter SDK installed ([flutter.dev](https://flutter.dev))
- A Supabase project set up with the schema above
- Android or iOS device/emulator

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-username/campus-flow.git
cd campus-flow

# 2. Install dependencies
flutter pub get

# 3. Add your Supabase credentials in main.dart
#    Replace the URL and anonKey with your project's values
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);

# 4. Generate app icons
flutter pub run flutter_launcher_icons

# 5. Run the app
flutter run
```

---

## Future Scope

- [ ] **Indoor Navigation** — Map API integration to guide students to the exact room door
- [ ] **Push Notifications** — Alert students the moment their professor cancels a class (via Supabase Edge Functions)
- [ ] **Attendance Integration** — Use the existing QR system for professors to mark attendance directly in-app

---

## Developer

**Ayush Satish Khatal**
B.Tech Computer Science, Second Year — VIT Pune

---

## 📄 License

This project is currently unlicensed and intended for academic/personal use at VIT Pune.
