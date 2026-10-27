# WardFit

WardFit is a mobile wardrobe management and outfit recommendation app built with **Flutter** and **Python (FastAPI)**. The goal of the project is to make picking daily outfits faster by combining what you already own in your closet with the current weather, your schedule for tomorrow, and monthly wear tracking.

## Features

- **Digital Closet (`My Clothes`)**: Browse clothes by category (`Shirts`, `Pants`, `Outwear`, `Shoes`), search by name/color/tags, mark favorites, and add new items with photo previews.
- **Smart Outfit Suggestions**: Picks daily and next-day outfits based on weather conditions (e.g., rainy/cold campus days) and tomorrow's plan (`workplace`, `free`, or trying something new).
- **Today's Wardrobe Calendar**: Hourly schedule view (`8:00 AM` – `7:00 PM`) showing planned daytime and evening outfits.
- **WardFIT360 Analytics**: Grouped bar chart tracking how often key items in your closet are worn across `JAN`, `FEB`, and `MAR`, paired with weekly color/energy tips.
- **AI Stylist Assistant**: Quick in-app chat helper accessible from the bottom bar for outfit ideas.

## Project Structure

```text
wardfit/
├── client/                 # Flutter mobile & web frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/         # Data models (clothes, recommendations, analytics)
│   │   ├── services/       # FastAPI HTTP client, mock fallback data, app state
│   │   ├── screens/        # All 8 UI screens (Login, Home, Search, Calendar, etc.)
│   │   ├── theme/          # Brand colors and light/dark theme setup
│   │   └── widgets/        # Custom bottom bar, hanger logo, garment illustrations
│   └── pubspec.yaml
└── server/                 # Python REST API
    ├── app.py              # FastAPI endpoints + SQLite persistence
    └── requirements.txt
```

## Tech Stack

- **Frontend:** Flutter (Dart), `ChangeNotifier` / `InheritedNotifier` state management, `CustomPainter` charts & illustrations, `http`
- **Backend:** Python 3, FastAPI, Uvicorn, SQLite (`sqlite3`)

## Getting Started

### 1. Run the Python Backend

Open a terminal inside `/server`, install the dependencies, and start the server:

```bash
cd server
python -m venv venv

# Windows
venv\Scripts\activate
# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
python app.py
```

The API runs at `http://127.0.0.1:8000` (interactive API docs are available at `http://127.0.0.1:8000/docs`). On first launch, `app.py` automatically creates `wardfit.db` and seeds the starter closet items.

> **Note:** If you run the Flutter app without starting the Python server first, the client automatically falls back to local mock data so you can still test all screens offline.

### 2. Run the Flutter App

Open a second terminal inside `/client`:

```bash
cd client
flutter pub get
flutter run
```

- **Android Emulator:** Connects to `http://10.0.2.2:8000/api` automatically.
- **iOS Simulator / Web / Windows Desktop:** Connects to `http://127.0.0.1:8000/api`.

## Main API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/login` | Sign in with `@username` and load profile info |
| `GET` | `/api/clothes` | List closet items (supports `category` and `search` filters) |
| `POST` | `/api/clothes` | Add a new clothing item (`name`, `color`, `tags`, `image_key`) |
| `PATCH` | `/api/clothes/{id}/favorite` | Toggle favorite heart status on an item |
| `GET` | `/api/recommendations` | Fetch daily outfit, schedule, and tips based on weather & plans |
| `GET` | `/api/analytics` | Fetch `WardFIT360 Analytics` monthly wear counts (`JAN`–`MAR`) |
| `POST` | `/api/chat` | Ask the AI Stylist assistant for outfit advice |

## Current Status & Roadmap

Currently, the app runs as a functional UI/UX prototype connected to a starter FastAPI backend with seeded mock data.

- [x] Complete 8-screen Flutter UI implementation & navigation flow
- [x] FastAPI starter endpoints & local offline fallback state
- [ ] Full JWT authentication & user registration flow
- [ ] Persistent image upload & cloud storage for user wardrobe items
- [ ] Live Weather API integration based on user location
