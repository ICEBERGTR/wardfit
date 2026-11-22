import base64
import hashlib
import os
import secrets
import sqlite3
import time
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

import httpx
import jwt
import uvicorn
from fastapi import Depends, FastAPI, File, Form, HTTPException, Query, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

app = FastAPI(title="WardFit API", version="1.1.0")

# Allow requests from Flutter web, desktop, and mobile emulators
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "wardfit.db")
UPLOADS_DIR = os.path.join(BASE_DIR, "uploads")
os.makedirs(UPLOADS_DIR, exist_ok=True)

# Serve uploaded clothing photos at /uploads/<filename>
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")

# JWT configuration
JWT_SECRET = os.environ.get("WARDFIT_JWT_SECRET", "wardfit-dev-secret-key-uog-2026")
JWT_ALGORITHM = "HS256"
JWT_EXPIRE_DAYS = 7

bearer_scheme = HTTPBearer(auto_error=False)

# Open-Meteo settings (Guelph, ON coordinates by default)
OPEN_METEO_URL = (
    "https://api.open-meteo.com/v1/forecast"
    "?latitude=43.5448&longitude=-80.2482&current=temperature_2m,weather_code"
)
WEATHER_CACHE_TTL_SECONDS = 15 * 60
_weather_cache: Dict[str, Any] = {
    "data": None,
    "timestamp": 0.0,
}


# --- Request / Response Schemas ---

class RegisterRequest(BaseModel):
    username: str
    password: str
    email: Optional[str] = "hello@reallygreatsite.com"


class LoginRequest(BaseModel):
    username: str
    password: str


class ProfileUpdateRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None


class ClothingCreate(BaseModel):
    name: str
    color: str
    tags: str
    category: Optional[str] = None
    image_key: Optional[str] = "grey_jacket"
    image_base64: Optional[str] = None


class ChatRequest(BaseModel):
    message: str
    weather: Optional[str] = None


# --- Password Hashing & JWT Helpers ---

def normalize_username(raw: str) -> str:
    cleaned = raw.strip()
    if not cleaned:
        return "@user"
    return cleaned if cleaned.startswith("@") else f"@{cleaned}"


def hash_password(password: str, salt_hex: Optional[str] = None) -> tuple[str, str]:
    if not salt_hex:
        salt_hex = secrets.token_hex(16)
    derived = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        bytes.fromhex(salt_hex),
        100_000,
    )
    return derived.hex(), salt_hex


def verify_password(password: str, stored_hash: str, salt_hex: str) -> bool:
    computed_hash, _ = hash_password(password, salt_hex)
    return secrets.compare_digest(computed_hash, stored_hash)


def create_jwt_token(user_id: int, username: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "username": username,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(days=JWT_EXPIRE_DAYS)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_jwt_token(token: str) -> Dict[str, Any]:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please sign in again.",
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
        )


# --- Database Setup & Migration ---

def get_db_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def infer_category(name: str, tags: str) -> str:
    text = f"{name} {tags}".lower()
    if any(w in text for w in ["jean", "pant", "trouser", "chino", "denim", "short"]):
        return "Pants"
    if any(w in text for w in ["shoe", "sneaker", "jordan", "nike", "boot"]):
        return "Shoes"
    if any(w in text for w in ["shirt", "tee", "sweatshirt", "sweater", "hoodie", "top", "lacoste", "uspa"]):
        return "Shirts"
    return "Outwear"


STARTER_CLOTHES = [
    # Outwear (Screen 7)
    ("Parachute jacket", "Outwear", "Beige", "rainy, coat, smart, casual", "parachute_jacket", 0),
    ("Relax jacket", "Outwear", "Brown", "cold, casual, hooded, winter", "relax_jacket", 0),
    ("Villa", "Outwear", "Blue / Yellow", "rainy, waterproof, sporty, bright", "villa_jacket", 1),
    # Pants (Screen 7)
    ("pink jean", "Pants", "Pink", "casual, bright, street, free", "pink_jean", 0),
    ("blue jean", "Pants", "Light Blue", "casual, everyday, denim", "blue_jean", 1),
    ("brown jean", "Pants", "Brown", "workplace, smart, earth-tone", "brown_jean", 0),
    ("black jeans", "Pants", "Black", "casual, rainy, everyday", "black_jeans", 1),
    ("fabric trousers", "Pants", "Black", "workplace, formal, evening", "fabric_trousers", 0),
    # Shirts
    ("Gryphon Sweatshirt", "Shirts", "Crimson Red", "casual, cold, rainy, campus", "gryphon_sweatshirt", 1),
    ("Blue shirt", "Shirts", "Light Blue", "workplace, smart, evening, warm", "blue_shirt", 0),
    ("yellow uspa shirt", "Shirts", "Yellow", "energy, sunny, warm, casual", "yellow_shirt", 0),
    ("Purple sweater", "Shirts", "Purple", "cold, cozy, casual", "purple_sweater", 0),
    # Shoes
    ("Blue Nike Shoes", "Shoes", "Blue", "sporty, everyday, walking", "blue_nike_shoes", 1),
    ("air jordan shoes", "Shoes", "Red / White", "street, casual, weekend", "air_jordan_shoes", 0),
]


def seed_clothes_for_user(cursor: sqlite3.Cursor, user_id: int) -> None:
    cursor.executemany(
        """
        INSERT INTO clothes (user_id, name, category, color, tags, image_key, image_url, is_favorite)
        VALUES (?, ?, ?, ?, ?, ?, NULL, ?)
        """,
        [(user_id, n, cat, col, t, ik, fav) for (n, cat, col, t, ik, fav) in STARTER_CLOTHES],
    )


def init_db() -> None:
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Create users table
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '+123-456-7890',
            address TEXT NOT NULL DEFAULT '123 Anywhere St., Any City, ST 12345',
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )

    # 2. Create clothes table (or migrate v1.0 schema if needed)
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS clothes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL DEFAULT 1,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            color TEXT NOT NULL,
            tags TEXT NOT NULL,
            image_key TEXT NOT NULL,
            image_url TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0
        )
        """
    )

    # Check existing columns on clothes table in case wardfit.db was created in v1.0
    cursor.execute("PRAGMA table_info(clothes)")
    existing_cols = {row["name"] for row in cursor.fetchall()}
    if "user_id" not in existing_cols:
        cursor.execute("ALTER TABLE clothes ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1")
    if "image_url" not in existing_cols:
        cursor.execute("ALTER TABLE clothes ADD COLUMN image_url TEXT")

    # 3. Seed default demo user (@user / wardfit123)
    cursor.execute("SELECT id FROM users WHERE username = ?", ("@user",))
    demo_row = cursor.fetchone()
    if not demo_row:
        pw_hash, salt = hash_password("wardfit123")
        created_at = datetime.now(timezone.utc).isoformat()
        cursor.execute(
            """
            INSERT INTO users (username, email, phone, address, password_hash, salt, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "@user",
                "hello@reallygreatsite.com",
                "+123-456-7890",
                "123 Anywhere St., Any City, ST 12345",
                pw_hash,
                salt,
                created_at,
            ),
        )
        demo_user_id = cursor.lastrowid
    else:
        demo_user_id = demo_row["id"]

    # 4. Seed starter clothes if db is empty
    cursor.execute("SELECT COUNT(*) as count FROM clothes")
    if cursor.fetchone()["count"] == 0:
        seed_clothes_for_user(cursor, demo_user_id)

    conn.commit()
    conn.close()


init_db()


def user_row_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
    return {
        "id": row["id"],
        "username": row["username"],
        "email": row["email"],
        "phone": row["phone"],
        "address": row["address"],
        "created_at": row["created_at"],
        "online": True,
    }


def cloth_row_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
    return {
        "id": row["id"],
        "user_id": row["user_id"],
        "name": row["name"],
        "category": row["category"],
        "color": row["color"],
        "tags": row["tags"],
        "image_key": row["image_key"],
        "image_url": row["image_url"],
        "is_favorite": bool(row["is_favorite"]),
    }


# --- Auth Dependencies ---

def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> Dict[str, Any]:
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Bearer authentication token.",
        )
    payload = decode_jwt_token(credentials.credentials)
    user_id = int(payload["sub"])

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account not found.",
        )
    return user_row_to_dict(row)


def get_optional_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> int:
    if credentials and credentials.credentials:
        try:
            payload = decode_jwt_token(credentials.credentials)
            return int(payload["sub"])
        except HTTPException:
            pass
    return 1


# --- Live Open-Meteo Weather Service ---

def map_wmo_code_to_condition(code: int) -> str:
    if code in (0, 1):
        return "Clear"
    if code in (2, 3):
        return "Cloudy"
    if code in (45, 48):
        return "Foggy"
    if code in (51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82):
        return "Rainy"
    if code in (71, 73, 75, 77, 85, 86):
        return "Snowy"
    if code in (95, 96, 99):
        return "Stormy"
    return "Rainy"


def fetch_live_weather(force_refresh: bool = False) -> Dict[str, Any]:
    now = time.time()
    cached = _weather_cache.get("data")
    if (
        not force_refresh
        and cached is not None
        and (now - _weather_cache.get("timestamp", 0.0)) < WEATHER_CACHE_TTL_SECONDS
    ):
        return {**cached, "source": "cache"}

    try:
        with httpx.Client(timeout=3.0) as client:
            resp = client.get(OPEN_METEO_URL)
            resp.raise_for_status()
            payload = resp.json()

        current = payload.get("current", {})
        temp_raw = float(current.get("temperature_2m", 6.0))
        temp_rounded = round(temp_raw)
        wmo_code = int(current.get("weather_code", 61))
        condition = map_wmo_code_to_condition(wmo_code)
        label = f"{condition} {temp_rounded}°C"

        result = {
            "label": label,
            "temperature_c": temp_raw,
            "condition": condition,
            "weather_code": wmo_code,
            "location": "Guelph, ON",
            "source": "open-meteo",
        }
        _weather_cache["data"] = result
        _weather_cache["timestamp"] = now
        return result
    except Exception:
        # Offline fallback matching the default UI specification
        fallback = {
            "label": "Rainy 6°C",
            "temperature_c": 6.0,
            "condition": "Rainy",
            "weather_code": 61,
            "location": "Guelph, ON",
            "source": "fallback",
        }
        return fallback


def save_image_bytes(raw_bytes: bytes) -> str:
    filename = f"{uuid.uuid4().hex}.png"
    file_path = os.path.join(UPLOADS_DIR, filename)
    with open(file_path, "wb") as f:
        f.write(raw_bytes)
    return f"/uploads/{filename}"


# --- API Endpoints ---

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "WardFit Backend", "version": "1.1.0"}


@app.post("/api/auth/register", status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest):
    username = normalize_username(payload.username)
    password = payload.password.strip()
    if len(password) < 4:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 4 characters.",
        )

    email = (payload.email or "hello@reallygreatsite.com").strip()
    pw_hash, salt = hash_password(password)
    created_at = datetime.now(timezone.utc).isoformat()

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM users WHERE LOWER(username) = LOWER(?)", (username,))
    if cursor.fetchone():
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Username {username} is already taken.",
        )

    cursor.execute(
        """
        INSERT INTO users (username, email, phone, address, password_hash, salt, created_at)
        VALUES (?, ?, '+123-456-7890', '123 Anywhere St., Any City, ST 12345', ?, ?, ?)
        """,
        (username, email, pw_hash, salt, created_at),
    )
    new_user_id = cursor.lastrowid
    seed_clothes_for_user(cursor, new_user_id)
    conn.commit()

    cursor.execute("SELECT * FROM users WHERE id = ?", (new_user_id,))
    user_dict = user_row_to_dict(cursor.fetchone())
    conn.close()

    token = create_jwt_token(new_user_id, user_dict["username"])
    return {
        "token": token,
        "user": user_dict,
        **user_dict,
    }


@app.post("/api/auth/login")
def login(payload: LoginRequest):
    username = normalize_username(payload.username)
    password = payload.password

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE LOWER(username) = LOWER(?)", (username,))
    row = cursor.fetchone()
    conn.close()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account not found. Use @user / wardfit123 or Sign up.",
        )

    # Allow demo @user quick sign-in if password field was left blank during rapid UI testing,
    # otherwise verify PBKDF2-SHA256 password hash strictly.
    is_blank_demo = row["username"] == "@user" and password == ""
    if not is_blank_demo and not verify_password(password, row["password_hash"], row["salt"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password.",
        )

    user_dict = user_row_to_dict(row)
    token = create_jwt_token(row["id"], row["username"])
    return {
        "token": token,
        "user": user_dict,
        **user_dict,
    }


@app.get("/api/auth/me")
def get_me(current_user: Dict[str, Any] = Depends(get_current_user)):
    return current_user


@app.patch("/api/auth/me")
def update_me(
    payload: ProfileUpdateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    conn = get_db_connection()
    cursor = conn.cursor()

    new_username = (
        normalize_username(payload.username)
        if payload.username and payload.username.strip()
        else current_user["username"]
    )
    new_email = payload.email.strip() if payload.email else current_user["email"]
    new_phone = payload.phone.strip() if payload.phone else current_user["phone"]
    new_address = payload.address.strip() if payload.address else current_user["address"]

    cursor.execute(
        """
        UPDATE users
        SET username = ?, email = ?, phone = ?, address = ?
        WHERE id = ?
        """,
        (new_username, new_email, new_phone, new_address, current_user["id"]),
    )
    conn.commit()
    cursor.execute("SELECT * FROM users WHERE id = ?", (current_user["id"],))
    updated = user_row_to_dict(cursor.fetchone())
    conn.close()
    return updated


@app.get("/api/weather")
def get_weather(refresh: bool = Query(default=False)):
    return fetch_live_weather(force_refresh=refresh)


@app.get("/api/clothes")
def get_clothes(
    category: Optional[str] = Query(default=None),
    search: Optional[str] = Query(default=None),
    user_id: int = Depends(get_optional_user_id),
):
    conn = get_db_connection()
    cursor = conn.cursor()

    query = "SELECT * FROM clothes WHERE user_id = ?"
    params: List[Any] = [user_id]

    if category and category != "See All":
        query += " AND LOWER(category) = LOWER(?)"
        params.append(category)

    if search and search.strip():
        q = f"%{search.strip().lower()}%"
        query += " AND (LOWER(name) LIKE ? OR LOWER(color) LIKE ? OR LOWER(tags) LIKE ?)"
        params.extend([q, q, q])

    query += " ORDER BY id DESC"
    cursor.execute(query, params)
    items = [cloth_row_to_dict(r) for r in cursor.fetchall()]
    conn.close()
    return {"items": items, "count": len(items)}


@app.post("/api/clothes", status_code=status.HTTP_201_CREATED)
def add_clothing_item(
    item: ClothingCreate,
    user_id: int = Depends(get_optional_user_id),
):
    name = item.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Item name is required.")

    color = item.color.strip() or "Grey"
    tags = item.tags.strip() or "casual"
    category = item.category or infer_category(name, tags)
    image_key = item.image_key or "grey_jacket"
    image_url: Optional[str] = None

    # Decode base64 photo if sent from Flutter Web/Desktop
    if item.image_base64 and item.image_base64.strip():
        raw_b64 = item.image_base64.strip()
        if "," in raw_b64:
            raw_b64 = raw_b64.split(",", 1)[1]
        try:
            decoded_bytes = base64.b64decode(raw_b64)
            image_url = save_image_bytes(decoded_bytes)
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"Invalid image data: {exc}")

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO clothes (user_id, name, category, color, tags, image_key, image_url, is_favorite)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0)
        """,
        (user_id, name, category, color, tags, image_key, image_url),
    )
    new_id = cursor.lastrowid
    conn.commit()

    cursor.execute("SELECT * FROM clothes WHERE id = ?", (new_id,))
    created = cloth_row_to_dict(cursor.fetchone())
    conn.close()
    return created


@app.post("/api/clothes/upload", status_code=status.HTTP_201_CREATED)
async def upload_clothing_item(
    name: str = Form(...),
    color: str = Form("Grey"),
    tags: str = Form("casual"),
    category: Optional[str] = Form(None),
    image_key: str = Form("grey_jacket"),
    file: UploadFile = File(...),
    user_id: int = Depends(get_optional_user_id),
):
    raw_bytes = await file.read()
    if not raw_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image file is empty.")

    image_url = save_image_bytes(raw_bytes)
    resolved_cat = category or infer_category(name, tags)

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO clothes (user_id, name, category, color, tags, image_key, image_url, is_favorite)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0)
        """,
        (user_id, name.strip(), resolved_cat, color.strip(), tags.strip(), image_key, image_url),
    )
    new_id = cursor.lastrowid
    conn.commit()

    cursor.execute("SELECT * FROM clothes WHERE id = ?", (new_id,))
    created = cloth_row_to_dict(cursor.fetchone())
    conn.close()
    return created


@app.patch("/api/clothes/{item_id}/favorite")
def toggle_favorite(
    item_id: int,
    user_id: int = Depends(get_optional_user_id),
):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM clothes WHERE id = ?", (item_id,))
    existing = cursor.fetchone()
    if not existing:
        conn.close()
        raise HTTPException(status_code=404, detail="Clothing item not found.")

    new_val = 0 if existing["is_favorite"] else 1
    cursor.execute("UPDATE clothes SET is_favorite = ? WHERE id = ?", (new_val, item_id))
    conn.commit()

    cursor.execute("SELECT * FROM clothes WHERE id = ?", (item_id,))
    updated = cloth_row_to_dict(cursor.fetchone())
    conn.close()
    return updated


def _pick_from_closet(
    clothes: List[Dict[str, Any]],
    category: str,
    preferred_keywords: List[str],
    fallback_name: str,
) -> Dict[str, Any]:
    cat_items = [c for c in clothes if c["category"].lower() == category.lower()]
    for kw in preferred_keywords:
        for item in cat_items:
            haystack = f"{item['name']} {item['tags']} {item['color']}".lower()
            if kw.lower() in haystack:
                return item
    if cat_items:
        return cat_items[0]
    return {"name": fallback_name, "image_key": "gryphon_sweatshirt"}


@app.get("/api/recommendations")
def get_recommendations(
    weather: Optional[str] = Query(default=None),
    plan: str = Query(default="default"),
    style_pref: str = Query(default="keep"),
    user_id: int = Depends(get_optional_user_id),
):
    # Use live Open-Meteo weather unless the caller explicitly passed a custom weather label
    live_weather = fetch_live_weather()
    active_weather = weather.strip() if (weather and weather.strip()) else live_weather["label"]

    # Parse temperature from weather string if overridden, else use live temperature
    temp_c = live_weather["temperature_c"]
    for token in active_weather.replace("°C", "").split():
        try:
            temp_c = float(token)
            break
        except ValueError:
            pass

    is_cold_or_wet = (
        temp_c < 12.0
        or any(w in active_weather.lower() for w in ["rain", "snow", "storm", "fog"])
    )

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM clothes WHERE user_id = ? ORDER BY id ASC", (user_id,))
    user_clothes = [cloth_row_to_dict(r) for r in cursor.fetchall()]
    conn.close()

    plan_lower = plan.lower()

    # Select outfit items dynamically from the user's SQLite wardrobe
    if "work" in plan_lower:
        top = _pick_from_closet(user_clothes, "Shirts", ["workplace", "blue shirt", "smart"], "Blue shirt")
        bottom = _pick_from_closet(user_clothes, "Pants", ["fabric", "workplace", "brown"], "fabric trousers")
        eve_top = _pick_from_closet(user_clothes, "Outwear", ["parachute", "smart", "coat"], "Parachute jacket")
        eve_bottom = _pick_from_closet(user_clothes, "Pants", ["brown", "jean"], "brown jean")
    elif "new" in plan_lower or style_pref == "change":
        top = _pick_from_closet(user_clothes, "Outwear", ["villa", "bright", "sporty"], "Villa")
        bottom = _pick_from_closet(user_clothes, "Pants", ["pink", "bright"], "pink jean")
        eve_top = _pick_from_closet(user_clothes, "Shirts", ["yellow", "purple"], "yellow uspa shirt")
        eve_bottom = _pick_from_closet(user_clothes, "Pants", ["blue jean", "denim"], "blue jean")
    elif "free" in plan_lower:
        top = _pick_from_closet(user_clothes, "Shirts", ["purple", "cozy", "casual"], "Purple sweater")
        bottom = _pick_from_closet(user_clothes, "Pants", ["blue jean", "casual"], "blue jean")
        eve_top = _pick_from_closet(user_clothes, "Outwear", ["relax", "hooded"], "Relax jacket")
        eve_bottom = _pick_from_closet(user_clothes, "Pants", ["black", "jean"], "black jeans")
    elif is_cold_or_wet:
        top = _pick_from_closet(user_clothes, "Shirts", ["gryphon", "sweatshirt", "cold", "rainy"], "Gryphon Sweatshirt")
        bottom = _pick_from_closet(user_clothes, "Pants", ["black jeans", "rainy"], "black jeans")
        eve_top = _pick_from_closet(user_clothes, "Shirts", ["blue shirt", "smart"], "Blue shirt")
        eve_bottom = _pick_from_closet(user_clothes, "Pants", ["fabric trousers", "formal"], "fabric trousers")
    else:
        # Warm weather (>= 12°C and clear/cloudy)
        top = _pick_from_closet(user_clothes, "Shirts", ["yellow", "sunny", "warm"], "yellow uspa shirt")
        bottom = _pick_from_closet(user_clothes, "Pants", ["blue jean", "everyday"], "blue jean")
        eve_top = _pick_from_closet(user_clothes, "Shirts", ["blue shirt", "evening"], "Blue shirt")
        eve_bottom = _pick_from_closet(user_clothes, "Pants", ["brown jean", "fabric"], "fabric trousers")

    todays_outfit = f"{top['name']} + {bottom['name']}"
    evening_outfit = f"{eve_top['name']} + {eve_bottom['name']}"
    styles_remaining = max(14, len(user_clothes))

    return {
        "todays_outfit": todays_outfit,
        "weather": active_weather,
        "temperature_c": temp_c,
        "weather_source": live_weather["source"],
        "styles_remaining": styles_remaining,
        "monthly_styles_tried": 28,
        "tip": {
            "category": "Energy",
            "date": "Sat, 11 Jan",
            "message": "wearing yellow this week will make you feel more energised!",
        },
        "schedule": [
            {
                "time": "10:00 AM",
                "outfit": todays_outfit,
                "accent": "coral",
                "top_key": top.get("image_key", "gryphon_sweatshirt"),
                "bottom_key": bottom.get("image_key", "black_jeans"),
            },
            {
                "time": "7:00 PM",
                "outfit": evening_outfit,
                "accent": "blue",
                "top_key": eve_top.get("image_key", "blue_shirt"),
                "bottom_key": eve_bottom.get("image_key", "fabric_trousers"),
            },
        ],
    }


@app.get("/api/analytics")
def get_analytics():
    items = [
        {"label": "Blue Jean", "color_hex": "#00BCD4", "jan": 31, "feb": 25, "mar": 8},
        {"label": "Blue Sweat", "color_hex": "#29B6F6", "jan": 30, "feb": 24, "mar": 9},
        {"label": "Blue Nike Shoes", "color_hex": "#5C85E6", "jan": 31, "feb": 25, "mar": 7},
        {"label": "navy blue t shirt", "color_hex": "#7986CB", "jan": 30, "feb": 24, "mar": 8},
        {"label": "Purple sweater", "color_hex": "#9C59D1", "jan": 31, "feb": 25, "mar": 9},
        {"label": "red dress", "color_hex": "#C2085A", "jan": 31, "feb": 25, "mar": 8},
        {"label": "red lacoste shirt", "color_hex": "#E05246", "jan": 30, "feb": 24, "mar": 9},
        {"label": "orange addidas shirt", "color_hex": "#F29141", "jan": 31, "feb": 25, "mar": 7},
        {"label": "air jordan shoes", "color_hex": "#F7B859", "jan": 30, "feb": 24, "mar": 8},
        {"label": "yellow uspa shirt", "color_hex": "#E4E868", "jan": 31, "feb": 25, "mar": 9},
    ]
    return {
        "months": ["JAN", "FEB", "MAR"],
        "max_y": 35,
        "monthly_styles_tried": 28,
        "series": items,
    }


@app.post("/api/chat")
def stylist_chat(
    req: ChatRequest,
    user_id: int = Depends(get_optional_user_id),
):
    msg = req.message.lower().strip()
    live_weather = fetch_live_weather()
    weather_label = req.weather or live_weather["label"]

    if "work" in msg or "office" in msg or "interview" in msg:
        reply = (
            f"For work tomorrow ({weather_label}), go with your Blue shirt + fabric trousers. "
            "Pair it with the Parachute jacket for the commute!"
        )
    elif "rain" in msg or "cold" in msg or "weather" in msg:
        reply = (
            f"Live weather in Guelph is {weather_label}. "
            "Your Gryphon Sweatshirt + black jeans with the Villa waterproof jacket will keep you warm."
        )
    elif "yellow" in msg or "energy" in msg or "bright" in msg:
        reply = "Try your yellow uspa shirt with blue jean! Bright tones boost your energy during grey weeks."
    else:
        reply = (
            f"With current conditions ({weather_label}), Gryphon Sweatshirt + black jeans is great for 10:00 AM, "
            "and Blue shirt + fabric trousers works nicely for 7:00 PM."
        )
    return {"reply": reply, "weather": weather_label}


if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
