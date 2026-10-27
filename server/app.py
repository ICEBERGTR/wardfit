import os
import sqlite3
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="WardFit API", version="1.0.0")

# Allow requests from Flutter web, desktop, and mobile emulators
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_PATH = os.path.join(os.path.dirname(__file__), "wardfit.db")


# --- Request / Response Schemas ---

class LoginRequest(BaseModel):
    username: str
    password: str


class ClothingCreate(BaseModel):
    name: str
    color: str
    tags: str
    category: Optional[str] = None
    image_key: Optional[str] = "grey_jacket"


class ChatRequest(BaseModel):
    message: str
    weather: Optional[str] = "Rainy 6°C"


# --- Database Setup & Seed Data ---

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def infer_category(name: str, tags: str) -> str:
    text = f"{name} {tags}".lower()
    if any(word in text for word in ["jean", "pant", "trouser", "chino", "denim", "short"]):
        return "Pants"
    if any(word in text for word in ["shoe", "sneaker", "jordan", "nike", "boot"]):
        return "Shoes"
    if any(word in text for word in ["shirt", "tee", "sweatshirt", "sweater", "hoodie", "top", "lacoste", "uspa"]):
        return "Shirts"
    return "Outwear"


def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS clothes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            color TEXT NOT NULL,
            tags TEXT NOT NULL,
            image_key TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0
        )
        """
    )

    # Seed initial wardrobe items matching the UI catalog if db is empty
    cursor.execute("SELECT COUNT(*) as count FROM clothes")
    if cursor.fetchone()["count"] == 0:
        starter_clothes = [
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
            ("Blue shirt", "Shirts", "Light Blue", "workplace, smart, evening", "blue_shirt", 0),
            ("yellow uspa shirt", "Shirts", "Yellow", "energy, sunny, casual", "yellow_shirt", 0),
            ("Purple sweater", "Shirts", "Purple", "cold, cozy, casual", "purple_sweater", 0),
            # Shoes
            ("Blue Nike Shoes", "Shoes", "Blue", "sporty, everyday, walking", "blue_nike_shoes", 1),
            ("air jordan shoes", "Shoes", "Red / White", "street, casual, weekend", "air_jordan_shoes", 0),
        ]
        cursor.executemany(
            """
            INSERT INTO clothes (name, category, color, tags, image_key, is_favorite)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            starter_clothes,
        )
        conn.commit()

    conn.close()


init_db()


def row_to_dict(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "category": row["category"],
        "color": row["color"],
        "tags": row["tags"],
        "image_key": row["image_key"],
        "is_favorite": bool(row["is_favorite"]),
    }


# --- API Endpoints ---

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "WardFit Backend"}


@app.post("/api/auth/login")
def login(payload: LoginRequest):
    raw_user = payload.username.strip() or "@user"
    username = raw_user if raw_user.startswith("@") else f"@{raw_user}"

    return {
        "username": username,
        "email": "hello@reallygreatsite.com",
        "phone": "+123-456-7890",
        "address": "123 Anywhere St., Any City, ST 12345",
        "online": True,
    }


@app.get("/api/clothes")
def get_clothes(
    category: Optional[str] = Query(default=None),
    search: Optional[str] = Query(default=None),
):
    conn = get_db_connection()
    cursor = conn.cursor()

    query = "SELECT * FROM clothes WHERE 1=1"
    params: List[str] = []

    if category and category != "See All":
        query += " AND LOWER(category) = LOWER(?)"
        params.append(category)

    if search and search.strip():
        q = f"%{search.strip().lower()}%"
        query += " AND (LOWER(name) LIKE ? OR LOWER(color) LIKE ? OR LOWER(tags) LIKE ?)"
        params.extend([q, q, q])

    query += " ORDER BY id DESC"
    cursor.execute(query, params)
    items = [row_to_dict(r) for r in cursor.fetchall()]
    conn.close()
    return {"items": items, "count": len(items)}


@app.post("/api/clothes", status_code=201)
def add_clothing_item(item: ClothingCreate):
    name = item.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Item name is required.")

    color = item.color.strip() or "Grey"
    tags = item.tags.strip() or "casual"
    category = item.category or infer_category(name, tags)
    image_key = item.image_key or "grey_jacket"

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO clothes (name, category, color, tags, image_key, is_favorite)
        VALUES (?, ?, ?, ?, ?, 0)
        """,
        (name, category, color, tags, image_key),
    )
    new_id = cursor.lastrowid
    conn.commit()

    cursor.execute("SELECT * FROM clothes WHERE id = ?", (new_id,))
    created = row_to_dict(cursor.fetchone())
    conn.close()
    return created


@app.patch("/api/clothes/{item_id}/favorite")
def toggle_favorite(item_id: int):
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
    updated = row_to_dict(cursor.fetchone())
    conn.close()
    return updated


@app.get("/api/recommendations")
def get_recommendations(
    weather: str = Query(default="Rainy 6°C"),
    plan: str = Query(default="default"),
    style_pref: str = Query(default="keep"),
):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) as count FROM clothes")
    total_clothes = cursor.fetchone()["count"]
    conn.close()

    weather_lower = weather.lower()
    plan_lower = plan.lower()

    # Match outfit based on user's plan for tomorrow and current weather
    if "work" in plan_lower:
        todays_outfit = "Blue shirt + fabric trousers"
        morning_outfit = "Blue shirt + fabric trousers"
        evening_outfit = "Parachute jacket + brown jean"
    elif "new" in plan_lower or style_pref == "change":
        todays_outfit = "Villa + pink jean"
        morning_outfit = "yellow uspa shirt + blue jean"
        evening_outfit = "Villa + pink jean"
    elif "free" in plan_lower:
        todays_outfit = "Purple sweater + blue jean"
        morning_outfit = "Purple sweater + blue jean"
        evening_outfit = "Relax jacket + black jeans"
    elif "sunny" in weather_lower:
        todays_outfit = "yellow uspa shirt + blue jean"
        morning_outfit = "yellow uspa shirt + blue jean"
        evening_outfit = "Blue shirt + brown jean"
    else:
        # Default rainy day campus/daily combo matching design screens
        todays_outfit = "Gryphon Sweatshirt + black jeans"
        morning_outfit = "Gryphon Sweatshirt + black jeans"
        evening_outfit = "Blue shirt + fabric trousers"

    styles_remaining = max(14, total_clothes)

    return {
        "todays_outfit": todays_outfit,
        "weather": weather,
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
                "outfit": morning_outfit,
                "accent": "coral",
                "top_key": "gryphon_sweatshirt" if "Gryphon" in morning_outfit else "blue_shirt",
                "bottom_key": "black_jeans" if "black" in morning_outfit else "fabric_trousers",
            },
            {
                "time": "7:00 PM",
                "outfit": evening_outfit,
                "accent": "blue",
                "top_key": "blue_shirt",
                "bottom_key": "fabric_trousers",
            },
        ],
    }


@app.get("/api/analytics")
def get_analytics():
    # Monthly wear counts across JAN, FEB, MAR for WardFIT360 Analytics chart
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
def stylist_chat(req: ChatRequest):
    msg = req.message.lower().strip()
    if "work" in msg or "office" in msg or "interview" in msg:
        reply = "For work tomorrow, go with your Blue shirt + fabric trousers. Bring the Parachute jacket if it's still 6°C!"
    elif "rain" in msg or "cold" in msg or "weather" in msg:
        reply = f"It's currently {req.weather}. Your Gryphon Sweatshirt + black jeans with the Villa rain jacket will keep you dry."
    elif "yellow" in msg or "energy" in msg or "bright" in msg:
        reply = "Try your yellow uspa shirt with blue jean! Bright tones boost your mood during grey winter weeks."
    else:
        reply = "Based on your closet, Gryphon Sweatshirt + black jeans is great for daytime, and Blue shirt + fabric trousers works nicely for 7:00 PM."
    return {"reply": reply}


if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
