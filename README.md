# WardFit (v1.1)

WardFit is a mobile and desktop wardrobe management and outfit recommendation application built with **Flutter** and **Python (FastAPI)**. It pairs your personal closet items with live local weather data, tomorrow's schedule, and monthly wear tracking so deciding what to wear takes seconds.

## What's New in v1.1

- **JWT Authentication & User Accounts**: Full sign-up and sign-in flow backed by SQLite `users` storage, `hashlib.pbkdf2_hmac('sha256', ...)` salted password hashing, and 7-day signed `PyJWT` (`HS256`) bearer tokens (`POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`).
- **Persistent Clothing Photo Uploads**: Adding an item on the `Add New Clothes` screen saves the uploaded or captured image to `/server/uploads/<uuid>.png` (served via FastAPI `StaticFiles` at `/uploads`) and links it to the user's SQLite closet.
- **Live Open-Meteo Weather Integration**: Queries the Open-Meteo forecast API (`GET /api/weather`) with a 15-minute in-memory cache and maps WMO weather codes to clean UI labels (`Rainy 6°C`, `Snowy -2°C`, `Cloudy 11°C`, `Clear 19°C`), dynamically adjusting daily and hourly outfit recommendations from the user's database items.

## Features

- **Digital Closet (`My Clothes`)**: Browse clothes by category (`Shirts`, `Pants`, `Outwear`, `Shoes`), filter by name/color/tags, toggle favorite hearts, and upload new clothing photos.
- **Smart Outfit Suggestions**: Recommends daytime and evening outfits based on live weather conditions and tomorrow's plan (`workplace`, `free`, or trying something new).
- **Today's Wardrobe Calendar**: Hourly timeline (`8:00 AM` – `7:00 PM`) displaying scheduled morning and evening outfits.
- **WardFIT360 Analytics**: Grouped bar chart comparing monthly wear counts across `JAN`, `FEB`, and `MAR` for key closet items, paired with weekly color/energy tips.
- **AI Stylist Assistant**: Built-in chat sheet accessible from the floating bottom-right button for quick outfit advice.

## Project Structure

```text
wardfit/
├── client/                 # Flutter frontend (Mobile, Web, Windows Desktop)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/         # Data models (clothes, recommendations, analytics)
│   │   ├── services/       # FastAPI HTTP + JWT client, image picker, app state
│   │   ├── screens/        # All 8 UI screens (Login/Signup, Home, Catalog, etc.)
│   │   ├── theme/          # Brand colors and light/dark theme setup
│   │   └── widgets/        # Custom bottom bar, hanger logo, garment illustrations
│   └── pubspec.yaml
└── server/                 # Python FastAPI backend
    ├── app.py              # REST endpoints, JWT auth, Open-Meteo client, SQLite
    ├── uploads/            # Persistent user clothing photos (/uploads/<uuid>.png)
    └── requirements.txt
```

## Tech Stack

- **Frontend:** Flutter (Dart), `ChangeNotifier` / `InheritedNotifier` state management, `CustomPainter` charts & illustrations, `http`
- **Backend:** Python 3.13, FastAPI, Uvicorn, SQLite (`sqlite3`), `PyJWT`, `httpx`, `python-multipart`

## Getting Started

### 1. Run the Python Backend

Open a terminal inside `/server`, activate your virtual environment, install the v1.1 dependencies, and start the server:

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

The API runs at `http://127.0.0.1:8000` (Swagger UI docs at `http://127.0.0.1:8000/docs`). On startup, `app.py` initializes `wardfit.db`, creates `/server/uploads`, and seeds the default demo account:
- **Demo Username:** `@user`
- **Demo Password:** `wardfit123`

> **Note:** If the Flutter client is launched without the backend running, it falls back to local mock data so all 8 screens remain testable offline.

### 2. Run the Flutter App

Open a second terminal inside `/client`:

```bash
cd client
flutter pub get
flutter run
```

- **Windows Desktop / Chrome Web / iOS Simulator:** Connects to `http://127.0.0.1:8000/api`.
- **Android Emulator:** Connects to `http://10.0.2.2:8000/api`.

## Main API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Register a new `@username`, seed starter closet, and return a 7-day JWT |
| `POST` | `/api/auth/login` | Authenticate with PBKDF2-SHA256 and return a signed JWT token |
| `GET` | `/api/auth/me` | Fetch current user profile (protected via `HTTPBearer`) |
| `PATCH` | `/api/auth/me` | Update user profile details in SQLite |
| `GET` | `/api/weather` | Fetch live Open-Meteo weather (15-min cache + offline fallback) |
| `GET` | `/api/clothes` | List user's closet items (supports `category` and `search` filters) |
| `POST` | `/api/clothes` | Add a new clothing item (supports `image_base64` -> `/uploads/<uuid>.png`) |
| `POST` | `/api/clothes/upload` | Upload a clothing item via `multipart/form-data` (`UploadFile`) |
| `PATCH` | `/api/clothes/{id}/favorite` | Toggle favorite heart status on an item |
| `GET` | `/api/recommendations` | Generate daily outfit & hourly schedule from SQLite closet + live weather |
| `GET` | `/api/analytics` | Fetch `WardFIT360 Analytics` monthly wear counts (`JAN`–`MAR`) |
| `POST` | `/api/chat` | Ask the AI Stylist assistant for weather-aware outfit ideas |

## Status & Roadmap

- [x] Complete 8-screen Flutter UI implementation & navigation flow
- [x] FastAPI REST endpoints & local offline fallback state
- [x] Full JWT authentication (`PyJWT` + `pbkdf2_hmac`) & user registration flow
- [x] Persistent image upload & `/uploads` static file serving for wardrobe items
- [x] Live Open-Meteo Weather API integration with WMO weather code mapping
