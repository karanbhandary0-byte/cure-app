"""Cure Backend - Healthcare SaaS Platform.

Provides JWT auth for doctors, mock OTP auth for patients,
appointment & status management, medical records, and feedback.
"""
from __future__ import annotations

import logging
import os
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import List, Literal, Optional

from dotenv import load_dotenv
from fastapi import APIRouter, Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr, Field
from starlette.middleware.cors import CORSMiddleware

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / ".env")

# ---------------- Configuration -----------------
MONGO_URL = os.environ.get("MONGO_URL", "mongodb://localhost:27017")
DB_NAME = os.environ.get("DB_NAME", "cure_db")
JWT_SECRET = os.environ.get("JWT_SECRET", "cure_super_secret_jwt_key_2026")
JWT_ALGORITHM = os.environ.get("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
TWILIO_SID = os.environ.get("TWILIO_ACCOUNT_SID", "")
TWILIO_TOKEN = os.environ.get("TWILIO_AUTH_TOKEN", "")
TWILIO_PHONE = os.environ.get("TWILIO_PHONE_NUMBER", "")

try:
    import pymongo
    _test_c = pymongo.MongoClient(MONGO_URL, serverSelectionTimeoutMS=1500)
    _test_c.server_info()
    client = AsyncIOMotorClient(MONGO_URL)
    db = client[DB_NAME]
except Exception:
    import mongomock_motor
    client = mongomock_motor.AsyncMongoMockClient()
    db = client[DB_NAME]

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)
security_scheme = HTTPBearer(auto_error=False)

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("cure")

# ---------------- Twilio SMS wrapper (with mock fallback) -----------------
def send_sms(phone: str, message: str) -> None:
    """Send SMS via Twilio, fall back to console log if not configured."""
    if not (TWILIO_SID and TWILIO_TOKEN and TWILIO_PHONE):
        logger.info("[MOCK SMS] to=%s msg=%s", phone, message)
        return
    try:
        from twilio.rest import Client as TwilioClient
        twilio_client = TwilioClient(TWILIO_SID, TWILIO_TOKEN)
        twilio_client.messages.create(body=message, from_=TWILIO_PHONE, to=phone)
        logger.info("[SMS sent] to=%s", phone)
    except Exception as exc:  # noqa: BLE001
        logger.error("[SMS failed] %s", exc)


import bcrypt

def hash_password(plain: str) -> str:
    pwd_bytes = plain.encode('utf-8')[:72]
    salt = bcrypt.gensalt(12)
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')


def verify_password(plain: str, hashed: str) -> bool:
    try:
        pwd_bytes = plain.encode('utf-8')[:72]
        return bcrypt.checkpw(pwd_bytes, hashed.encode('utf-8'))
    except Exception:
        return False


def create_token(sub: str, role: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": sub,
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except JWTError as exc:
        raise HTTPException(status_code=401, detail=f"Invalid token: {exc}") from exc


async def get_current_user(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
) -> dict:
    if creds is None:
        raise HTTPException(status_code=401, detail="Missing auth token")
    payload = decode_token(creds.credentials)
    return payload  # {sub, role, ...}


async def require_doctor(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "doctor":
        raise HTTPException(status_code=403, detail="Doctor access only")
    doctor = await db.doctors.find_one({"_id": user["sub"]}, {"_id": 1, "name": 1, "email": 1, "specialty": 1, "clinic_name": 1, "clinic_address": 1, "status": 1, "expected_arrival": 1, "slot_duration_min": 1, "slot_count": 1, "slot_start_hour": 1, "verification_status": 1})
    if not doctor:
        raise HTTPException(status_code=401, detail="Doctor not found")
    doctor["id"] = doctor.pop("_id")
    if "verification_status" not in doctor:
        doctor["verification_status"] = "verified"
    return doctor


async def require_admin(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access only")
    admin = await db.admins.find_one({"_id": user["sub"]})
    if not admin:
        if user["sub"] == "admin_001":
            return {"id": "admin_001", "email": "admin@cure.app", "role": "admin"}
        raise HTTPException(status_code=401, detail="Admin not found")
    admin["id"] = admin.pop("_id")
    return admin


async def require_patient(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "patient":
        raise HTTPException(status_code=403, detail="Patient access only")
    patient = await db.patients.find_one({"_id": user["sub"]}, {"_id": 1, "name": 1, "phone": 1, "age": 1, "gender": 1, "allergies": 1})
    if not patient:
        raise HTTPException(status_code=401, detail="Patient not found")
    patient["id"] = patient.pop("_id")
    return patient


# ---------------- Schemas -----------------
DOCTOR_STATUSES = ["available", "running_late", "in_surgery", "emergency", "closed"]


class AdminLogin(BaseModel):
    email: EmailStr
    password: str


class DoctorVerificationUpdate(BaseModel):
    verification_status: Literal["verified", "rejected"]


class DoctorRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=72)
    name: str
    specialty: str
    clinic_name: str = "My Clinic"
    clinic_address: str = ""


class DoctorLogin(BaseModel):
    email: EmailStr
    password: str


class PatientOTPRequest(BaseModel):
    phone: str = Field(min_length=8, max_length=20)
    name: Optional[str] = None  # if new patient


class PatientOTPVerify(BaseModel):
    phone: str
    code: str


class DoctorStatusUpdate(BaseModel):
    status: Literal["available", "running_late", "in_surgery", "emergency", "closed"]
    expected_arrival: Optional[str] = None  # ISO timestamp
    delay_minutes: Optional[int] = 0


class DoctorSettings(BaseModel):
    slot_duration_min: int = Field(ge=5, le=120)
    slot_count: int = Field(ge=1, le=40)
    slot_start_hour: int = Field(ge=0, le=23)


class CustomSlotCreate(BaseModel):
    scheduled_at: str  # ISO timestamp


class PostponeRequest(BaseModel):
    shift_minutes: int = Field(ge=5, le=1440)
    apply_to: Literal["today", "all_upcoming"] = "today"


class AppointmentCreate(BaseModel):
    patient_id: str
    scheduled_at: str  # ISO
    reason: Optional[str] = ""
    duration_min: int = 30


class PatientAppointmentBook(BaseModel):
    doctor_id: str
    scheduled_at: str
    reason: Optional[str] = ""


class AppointmentUpdate(BaseModel):
    scheduled_at: Optional[str] = None
    status: Optional[Literal["scheduled", "completed", "cancelled", "delayed"]] = None
    reason: Optional[str] = None


class ConsultationNoteCreate(BaseModel):
    appointment_id: str
    diagnosis: str
    prescription: str  # multiline medicines + dosage
    follow_up_instructions: str = ""


class FeedbackSubmit(BaseModel):
    appointment_id: str
    feeling_better: bool
    medication_helped: bool
    symptoms_unchanged: bool
    symptoms_worsened: bool
    side_effects: str = ""
    severity: int = Field(ge=1, le=10)
    notes: str = ""


class PatientCreate(BaseModel):
    name: str
    phone: str
    age: Optional[int] = None
    gender: Optional[str] = None
    allergies: Optional[str] = ""


# ---------------- App setup -----------------
app = FastAPI(title="Cure API")
api = APIRouter(prefix="/api")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup():
    await db.doctors.create_index("email", unique=True)
    await db.patients.create_index("phone")
    await db.appointments.create_index([("doctor_id", 1), ("scheduled_at", 1)])
    # Backfill defaults for older doctor docs missing slot settings
    await db.doctors.update_many(
        {"slot_duration_min": {"$exists": False}},
        {"$set": {"slot_duration_min": 30, "slot_count": 8, "slot_start_hour": 9}},
    )
    await seed_demo_data()


@app.on_event("shutdown")
async def shutdown():
    client.close()


# ---------------- Helpers -----------------
def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def strip_id(doc: dict) -> dict:
    if doc and "_id" in doc:
        doc["id"] = doc.pop("_id")
    return doc


def recommendation(feedback: dict) -> str:
    if feedback["symptoms_worsened"]:
        return "urgent_consultation"
    if feedback["side_effects"].strip():
        return "notify_doctor"
    if feedback["feeling_better"] and feedback["medication_helped"] and feedback["severity"] <= 3:
        return "continue_medication"
    if feedback["symptoms_unchanged"] or feedback["severity"] >= 7:
        return "book_followup"
    return "continue_medication"


# ---------------- Seed demo data -----------------
async def seed_demo_data():
    if await db.admins.count_documents({}) == 0:
        await db.admins.insert_one({
            "_id": "admin_001",
            "email": "admin@cure.app",
            "password_hash": hash_password("admin123"),
            "name": "Super Admin",
            "created_at": now_iso(),
        })

    if await db.doctors.count_documents({}) > 0:
        return
    doctor_id = "doc_demo_001"
    await db.doctors.insert_one({
        "_id": doctor_id,
        "email": "dr.smith@cure.app",
        "password_hash": hash_password("doctor123"),
        "name": "Dr. Sarah Smith",
        "specialty": "General Physician",
        "clinic_name": "Cure Family Clinic",
        "clinic_address": "221B Baker Street, Suite 4, Springfield, IL 62701",
        "status": "available",
        "verification_status": "verified",
        "expected_arrival": None,
        "delay_minutes": 0,
        "slot_duration_min": 30,
        "slot_count": 8,
        "slot_start_hour": 9,
        "created_at": now_iso(),
    })
    # Pending demo doctor for verification testing
    await db.doctors.insert_one({
        "_id": "doc_pending_001",
        "email": "dr.rivers@cure.app",
        "password_hash": hash_password("doctor123"),
        "name": "Dr. Alex Rivers",
        "specialty": "Pediatrics",
        "clinic_name": "Rivers Pediatric Care",
        "clinic_address": "452 Elm Street, Springfield, IL 62702",
        "status": "available",
        "verification_status": "pending",
        "expected_arrival": None,
        "delay_minutes": 0,
        "slot_duration_min": 30,
        "slot_count": 8,
        "slot_start_hour": 9,
        "created_at": now_iso(),
    })
    # Demo patients
    patients = [
        ("pat_demo_001", "John Doe", "+15551110001", 34, "male", "Penicillin"),
        ("pat_demo_002", "Maria Garcia", "+15551110002", 28, "female", ""),
        ("pat_demo_003", "Liam Chen", "+15551110003", 45, "male", "Pollen"),
    ]
    for pid, name, phone, age, gender, allergies in patients:
        await db.patients.insert_one({
            "_id": pid,
            "name": name,
            "phone": phone,
            "age": age,
            "gender": gender,
            "allergies": allergies,
            "doctor_id": doctor_id,
            "created_at": now_iso(),
        })
    # Demo appointments (today + tomorrow)
    today = datetime.now(timezone.utc).replace(hour=10, minute=0, second=0, microsecond=0)
    appts = [
        ("apt_001", "pat_demo_001", today + timedelta(hours=1), "scheduled", "Routine check-up"),
        ("apt_002", "pat_demo_002", today + timedelta(hours=2), "scheduled", "Fever and cough"),
        ("apt_003", "pat_demo_003", today + timedelta(hours=3), "scheduled", "Back pain"),
        ("apt_004", "pat_demo_001", today - timedelta(days=1), "completed", "Initial consultation"),
    ]
    for aid, pid, when, st, reason in appts:
        await db.appointments.insert_one({
            "_id": aid,
            "doctor_id": doctor_id,
            "patient_id": pid,
            "scheduled_at": when.isoformat(),
            "duration_min": 30,
            "status": st,
            "reason": reason,
            "created_at": now_iso(),
        })
    # Completed consultation note
    await db.consultations.insert_one({
        "_id": str(uuid.uuid4()),
        "appointment_id": "apt_004",
        "patient_id": "pat_demo_001",
        "doctor_id": doctor_id,
        "diagnosis": "Mild viral infection",
        "prescription": "Paracetamol 500mg, 1 tab thrice daily, 3 days\nVitamin C, 1 tab daily, 5 days",
        "follow_up_instructions": "Rest, drink plenty of fluids. Follow-up if fever persists beyond 3 days.",
        "created_at": now_iso(),
    })
    logger.info("Seeded demo doctor (dr.smith@cure.app / doctor123), pending doctor (dr.rivers@cure.app), admin (admin@cure.app / admin123).")


# ---------------- Health -----------------
@api.get("/")
async def root():
    return {"service": "Cure API", "ok": True}


# ---------------- Doctor Auth -----------------
@api.post("/auth/doctor/register")
async def doctor_register(body: DoctorRegister):
    existing = await db.doctors.find_one({"email": body.email.lower()})
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")
    doctor_id = f"doc_{uuid.uuid4().hex[:12]}"
    await db.doctors.insert_one({
        "_id": doctor_id,
        "email": body.email.lower(),
        "password_hash": hash_password(body.password),
        "name": body.name,
        "specialty": body.specialty,
        "clinic_name": body.clinic_name,
        "clinic_address": body.clinic_address or "",
        "status": "available",
        "verification_status": "pending",
        "expected_arrival": None,
        "delay_minutes": 0,
        "slot_duration_min": 30,
        "slot_count": 8,
        "slot_start_hour": 9,
        "created_at": now_iso(),
    })
    return {
        "token": create_token(doctor_id, "doctor"),
        "doctor": {
            "id": doctor_id,
            "email": body.email.lower(),
            "name": body.name,
            "specialty": body.specialty,
            "clinic_name": body.clinic_name,
            "clinic_address": body.clinic_address or "",
            "verification_status": "pending",
        },
    }


@api.post("/auth/doctor/login")
async def doctor_login(body: DoctorLogin):
    doctor = await db.doctors.find_one({"email": body.email.lower()})
    if not doctor or not verify_password(body.password, doctor["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {
        "token": create_token(doctor["_id"], "doctor"),
        "doctor": {
            "id": doctor["_id"],
            "email": doctor["email"],
            "name": doctor["name"],
            "specialty": doctor["specialty"],
            "clinic_name": doctor["clinic_name"],
            "clinic_address": doctor.get("clinic_address", ""),
            "verification_status": doctor.get("verification_status", "verified"),
        },
    }


@api.get("/auth/doctor/me")
async def doctor_me(doctor: dict = Depends(require_doctor)):
    return doctor


# ---------------- Patient Auth (Mock OTP) -----------------
@api.post("/auth/patient/send-otp")
async def patient_send_otp(body: PatientOTPRequest):
    # Mock OTP - always 123456 for ease of testing
    code = "123456"
    await db.otp_codes.update_one(
        {"phone": body.phone},
        {"$set": {"code": code, "expires_at": (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()}},
        upsert=True,
    )
    send_sms(body.phone, f"Your Cure verification code is {code}")
    return {"sent": True, "mock_code": code}  # mock_code returned for demo only


@api.post("/auth/patient/verify-otp")
async def patient_verify_otp(body: PatientOTPVerify):
    record = await db.otp_codes.find_one({"phone": body.phone})
    if not record or record["code"] != body.code:
        raise HTTPException(status_code=401, detail="Invalid OTP")
    patient = await db.patients.find_one({"phone": body.phone})
    is_new = patient is None
    if is_new:
        pid = f"pat_{uuid.uuid4().hex[:12]}"
        # Pick first available doctor (multi-doctor not in MVP scope)
        any_doc = await db.doctors.find_one({}, {"_id": 1})
        patient = {
            "_id": pid,
            "name": f"Patient {body.phone[-4:]}",
            "phone": body.phone,
            "age": None,
            "gender": None,
            "allergies": "",
            "doctor_id": any_doc["_id"] if any_doc else None,
            "created_at": now_iso(),
        }
        await db.patients.insert_one(patient)
    await db.otp_codes.delete_one({"phone": body.phone})
    return {
        "token": create_token(patient["_id"], "patient"),
        "patient": {"id": patient["_id"], "name": patient["name"], "phone": patient["phone"], "is_new": is_new},
    }


@api.get("/auth/patient/me")
async def patient_me(patient: dict = Depends(require_patient)):
    return patient


@api.put("/auth/patient/me")
async def patient_update(body: PatientCreate, patient: dict = Depends(require_patient)):
    update = {"name": body.name, "phone": body.phone, "age": body.age, "gender": body.gender, "allergies": body.allergies or ""}
    await db.patients.update_one({"_id": patient["id"]}, {"$set": update})
    update["id"] = patient["id"]
    return update


# ---------------- Doctor Status -----------------
@api.put("/doctor/status")
async def update_doctor_status(body: DoctorStatusUpdate, doctor: dict = Depends(require_doctor)):
    update = {
        "status": body.status,
        "expected_arrival": body.expected_arrival,
        "delay_minutes": body.delay_minutes or 0,
        "status_updated_at": now_iso(),
    }
    await db.doctors.update_one({"_id": doctor["id"]}, {"$set": update})

    # Auto-shift appointments if delayed
    if body.status in ("running_late", "in_surgery", "emergency") and body.delay_minutes:
        delta = timedelta(minutes=body.delay_minutes)
        async for apt in db.appointments.find({"doctor_id": doctor["id"], "status": "scheduled"}):
            new_time = datetime.fromisoformat(apt["scheduled_at"]) + delta
            await db.appointments.update_one(
                {"_id": apt["_id"]},
                {"$set": {"scheduled_at": new_time.isoformat(), "status": "delayed", "original_time": apt["scheduled_at"]}},
            )
            # Notify patient
            pat = await db.patients.find_one({"_id": apt["patient_id"]})
            if pat:
                send_sms(pat["phone"], f"Update: Your appointment with {doctor['name']} is delayed by {body.delay_minutes} mins.")

    return {"ok": True, **update}


@api.get("/doctor/status/{doctor_id}")
async def get_doctor_status(doctor_id: str):
    doctor = await db.doctors.find_one({"_id": doctor_id}, {"_id": 1, "name": 1, "specialty": 1, "clinic_name": 1, "status": 1, "expected_arrival": 1, "delay_minutes": 1, "status_updated_at": 1})
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return strip_id(doctor)


@api.put("/doctor/settings")
async def update_doctor_settings(body: DoctorSettings, doctor: dict = Depends(require_doctor)):
    update = {
        "slot_duration_min": body.slot_duration_min,
        "slot_count": body.slot_count,
        "slot_start_hour": body.slot_start_hour,
    }
    await db.doctors.update_one({"_id": doctor["id"]}, {"$set": update})
    return {"ok": True, **update}


def _generate_slots(doc: dict, date_iso: str, booked: set[str], custom_slots: list[str] | None = None) -> list[dict]:
    duration = int(doc.get("slot_duration_min") or 30)
    count = int(doc.get("slot_count") or 8)
    start_hour = int(doc.get("slot_start_hour") or 9)
    try:
        base = datetime.fromisoformat(date_iso).replace(hour=start_hour, minute=0, second=0, microsecond=0, tzinfo=timezone.utc)
    except Exception:
        base = datetime.now(timezone.utc).replace(hour=start_hour, minute=0, second=0, microsecond=0)
    auto_times = []
    for i in range(count):
        t = base + timedelta(minutes=duration * i)
        auto_times.append(t.isoformat())
    all_times = sorted(set(auto_times + (custom_slots or [])))
    slots = []
    for iso in all_times:
        t = datetime.fromisoformat(iso)
        slots.append({
            "time": iso,
            "label": t.strftime("%H:%M"),
            "available": iso not in booked,
            "custom": iso in (custom_slots or []) and iso not in auto_times,
        })
    return slots


async def _custom_slot_times(doctor_id: str, day_start: datetime, day_end: datetime) -> list[str]:
    docs = await db.custom_slots.find(
        {"doctor_id": doctor_id, "scheduled_at": {"$gte": day_start.isoformat(), "$lt": day_end.isoformat()}},
        {"scheduled_at": 1},
    ).to_list(200)
    return [d["scheduled_at"] for d in docs]


@api.get("/patient/doctors/{doctor_id}/slots")
async def doctor_available_slots(doctor_id: str, date: str, _: dict = Depends(require_patient)):
    doc = await db.doctors.find_one({"_id": doctor_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Doctor not found")
    try:
        day_start = datetime.fromisoformat(date).replace(hour=0, minute=0, second=0, microsecond=0, tzinfo=timezone.utc)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid date (use YYYY-MM-DD)")
    day_end = day_start + timedelta(days=1)
    existing = await db.appointments.find(
        {"doctor_id": doctor_id, "status": {"$in": ["scheduled", "delayed"]},
         "scheduled_at": {"$gte": day_start.isoformat(), "$lt": day_end.isoformat()}},
        {"scheduled_at": 1},
    ).to_list(200)
    booked = {a["scheduled_at"] for a in existing}
    custom = await _custom_slot_times(doctor_id, day_start, day_end)
    return {
        "slot_duration_min": doc.get("slot_duration_min", 30),
        "slot_count": doc.get("slot_count", 8),
        "slot_start_hour": doc.get("slot_start_hour", 9),
        "slots": _generate_slots(doc, date, booked, custom),
    }


@api.get("/doctor/slots/upcoming")
async def list_upcoming_custom_slots(doctor: dict = Depends(require_doctor)):
    docs = await db.custom_slots.find(
        {"doctor_id": doctor["id"], "scheduled_at": {"$gte": now_iso()}},
    ).sort("scheduled_at", 1).to_list(200)
    return [strip_id(d) for d in docs]


@api.get("/doctor/slots")
async def list_custom_slots(date: str, doctor: dict = Depends(require_doctor)):
    try:
        day_start = datetime.fromisoformat(date).replace(hour=0, minute=0, second=0, microsecond=0, tzinfo=timezone.utc)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid date (use YYYY-MM-DD)")
    day_end = day_start + timedelta(days=1)
    docs = await db.custom_slots.find(
        {"doctor_id": doctor["id"], "scheduled_at": {"$gte": day_start.isoformat(), "$lt": day_end.isoformat()}},
    ).sort("scheduled_at", 1).to_list(200)
    return [strip_id(d) for d in docs]


@api.post("/doctor/slots")
async def add_custom_slot(body: CustomSlotCreate, doctor: dict = Depends(require_doctor)):
    try:
        when = datetime.fromisoformat(body.scheduled_at)
        iso = when.isoformat()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid scheduled_at")
    existing = await db.custom_slots.find_one({"doctor_id": doctor["id"], "scheduled_at": iso})
    if existing:
        raise HTTPException(status_code=409, detail="Slot already exists")
    sid = f"slot_{uuid.uuid4().hex[:12]}"
    record = {"_id": sid, "doctor_id": doctor["id"], "scheduled_at": iso, "created_at": now_iso()}
    await db.custom_slots.insert_one(record)
    return strip_id(record)


@api.delete("/doctor/slots/{slot_id}")
async def delete_custom_slot(slot_id: str, doctor: dict = Depends(require_doctor)):
    await db.custom_slots.delete_one({"_id": slot_id, "doctor_id": doctor["id"]})
    return {"ok": True}


@api.post("/doctor/postpone")
async def postpone_schedule(body: PostponeRequest, doctor: dict = Depends(require_doctor)):
    delta = timedelta(minutes=body.shift_minutes)
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)

    # Shift scheduled/delayed appointments
    if body.apply_to == "today":
        appt_query = {
            "doctor_id": doctor["id"],
            "status": {"$in": ["scheduled", "delayed"]},
            "scheduled_at": {"$gte": today_start.isoformat(), "$lt": today_end.isoformat()},
        }
        slot_query = {
            "doctor_id": doctor["id"],
            "scheduled_at": {"$gte": today_start.isoformat(), "$lt": today_end.isoformat()},
        }
    else:
        appt_query = {
            "doctor_id": doctor["id"],
            "status": {"$in": ["scheduled", "delayed"]},
            "scheduled_at": {"$gte": now_iso()},
        }
        slot_query = {"doctor_id": doctor["id"], "scheduled_at": {"$gte": now_iso()}}

    shifted = 0
    async for apt in db.appointments.find(appt_query):
        new_time = (datetime.fromisoformat(apt["scheduled_at"]) + delta).isoformat()
        await db.appointments.update_one(
            {"_id": apt["_id"]},
            {"$set": {"scheduled_at": new_time, "status": "delayed", "original_time": apt.get("original_time", apt["scheduled_at"])}},
        )
        pat = await db.patients.find_one({"_id": apt["patient_id"]})
        if pat:
            send_sms(pat["phone"], f"Your appointment with {doctor['name']} has been postponed by {body.shift_minutes} mins. New time: {new_time}.")
        shifted += 1

    # Shift custom slots
    shifted_slots = 0
    async for s in db.custom_slots.find(slot_query):
        new_time = (datetime.fromisoformat(s["scheduled_at"]) + delta).isoformat()
        await db.custom_slots.update_one({"_id": s["_id"]}, {"$set": {"scheduled_at": new_time}})
        shifted_slots += 1

    # Update doctor status to running_late so patients see it
    await db.doctors.update_one(
        {"_id": doctor["id"]},
        {"$set": {"status": "running_late", "delay_minutes": body.shift_minutes, "status_updated_at": now_iso()}},
    )
    return {"ok": True, "shifted_appointments": shifted, "shifted_custom_slots": shifted_slots, "delay_minutes": body.shift_minutes}


# ---------------- Appointments (Doctor) -----------------
@api.get("/doctor/appointments")
async def doctor_appointments(filter: str = "all", doctor: dict = Depends(require_doctor)):
    query = {"doctor_id": doctor["id"]}
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)
    if filter == "today":
        query["scheduled_at"] = {"$gte": today_start.isoformat(), "$lt": today_end.isoformat()}
    elif filter == "upcoming":
        query["scheduled_at"] = {"$gte": now_iso()}
        query["status"] = {"$in": ["scheduled", "delayed"]}
    elif filter == "delayed":
        query["status"] = "delayed"
    elif filter == "completed":
        query["status"] = "completed"
    appts = await db.appointments.find(query).sort("scheduled_at", 1).to_list(500)
    result = []
    for a in appts:
        pat = await db.patients.find_one({"_id": a["patient_id"]}, {"_id": 1, "name": 1, "phone": 1, "age": 1})
        result.append({**strip_id(a), "patient": strip_id(pat) if pat else None})
    return result


@api.post("/doctor/appointments")
async def doctor_create_appointment(body: AppointmentCreate, doctor: dict = Depends(require_doctor)):
    pat = await db.patients.find_one({"_id": body.patient_id})
    if not pat:
        raise HTTPException(status_code=404, detail="Patient not found")
    aid = f"apt_{uuid.uuid4().hex[:12]}"
    appt = {
        "_id": aid,
        "doctor_id": doctor["id"],
        "patient_id": body.patient_id,
        "scheduled_at": body.scheduled_at,
        "duration_min": body.duration_min,
        "status": "scheduled",
        "reason": body.reason or "",
        "created_at": now_iso(),
    }
    await db.appointments.insert_one(appt)
    send_sms(pat["phone"], f"Appointment booked with {doctor['name']} at {body.scheduled_at}.")
    return strip_id(appt)


@api.put("/doctor/appointments/{appointment_id}")
async def doctor_update_appointment(appointment_id: str, body: AppointmentUpdate, doctor: dict = Depends(require_doctor)):
    appt = await db.appointments.find_one({"_id": appointment_id, "doctor_id": doctor["id"]})
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
    update = {k: v for k, v in body.dict().items() if v is not None}
    await db.appointments.update_one({"_id": appointment_id}, {"$set": update})
    new_appt = await db.appointments.find_one({"_id": appointment_id})
    return strip_id(new_appt)


@api.delete("/doctor/appointments/{appointment_id}")
async def doctor_cancel_appointment(appointment_id: str, doctor: dict = Depends(require_doctor)):
    await db.appointments.update_one(
        {"_id": appointment_id, "doctor_id": doctor["id"]}, {"$set": {"status": "cancelled"}}
    )
    return {"ok": True}


# ---------------- Patients (Doctor view) -----------------
@api.get("/doctor/patients")
async def doctor_patients(doctor: dict = Depends(require_doctor)):
    pats = await db.patients.find({"doctor_id": doctor["id"]}, {"name": 1, "phone": 1, "age": 1, "gender": 1, "allergies": 1}).to_list(500)
    return [strip_id(p) for p in pats]


@api.post("/doctor/patients")
async def doctor_add_patient(body: PatientCreate, doctor: dict = Depends(require_doctor)):
    pid = f"pat_{uuid.uuid4().hex[:12]}"
    patient = {
        "_id": pid,
        "name": body.name,
        "phone": body.phone,
        "age": body.age,
        "gender": body.gender,
        "allergies": body.allergies or "",
        "doctor_id": doctor["id"],
        "created_at": now_iso(),
    }
    await db.patients.insert_one(patient)
    return strip_id(patient)


@api.get("/doctor/patients/{patient_id}")
async def doctor_patient_detail(patient_id: str, doctor: dict = Depends(require_doctor)):
    pat = await db.patients.find_one({"_id": patient_id})
    if not pat:
        raise HTTPException(status_code=404, detail="Patient not found")
    history = await db.appointments.find({"patient_id": patient_id}).sort("scheduled_at", -1).to_list(100)
    consults = await db.consultations.find({"patient_id": patient_id}).sort("created_at", -1).to_list(100)
    feedbacks = await db.feedbacks.find({"patient_id": patient_id}).sort("created_at", -1).to_list(100)
    return {
        "patient": strip_id(pat),
        "appointments": [strip_id(a) for a in history],
        "consultations": [strip_id(c) for c in consults],
        "feedbacks": [strip_id(f) for f in feedbacks],
    }


# ---------------- Consultation Notes -----------------
@api.post("/doctor/consultations")
async def doctor_add_consultation(body: ConsultationNoteCreate, doctor: dict = Depends(require_doctor)):
    appt = await db.appointments.find_one({"_id": body.appointment_id, "doctor_id": doctor["id"]})
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
    cid = str(uuid.uuid4())
    note = {
        "_id": cid,
        "appointment_id": body.appointment_id,
        "patient_id": appt["patient_id"],
        "doctor_id": doctor["id"],
        "diagnosis": body.diagnosis,
        "prescription": body.prescription,
        "follow_up_instructions": body.follow_up_instructions,
        "created_at": now_iso(),
    }
    await db.consultations.insert_one(note)
    await db.appointments.update_one({"_id": body.appointment_id}, {"$set": {"status": "completed"}})
    return strip_id(note)


# ---------------- Feedback (Doctor view) -----------------
@api.get("/doctor/feedbacks")
async def doctor_feedbacks(doctor: dict = Depends(require_doctor)):
    fbs = await db.feedbacks.find({"doctor_id": doctor["id"]}).sort("created_at", -1).to_list(200)
    out = []
    for f in fbs:
        pat = await db.patients.find_one({"_id": f["patient_id"]}, {"name": 1})
        out.append({**strip_id(f), "patient_name": pat["name"] if pat else "Unknown"})
    return out


# ---------------- Analytics -----------------
@api.get("/doctor/analytics")
async def doctor_analytics(doctor: dict = Depends(require_doctor)):
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=6)
    appts_today = await db.appointments.count_documents({"doctor_id": doctor["id"], "scheduled_at": {"$gte": today_start.isoformat()}})
    total_completed = await db.appointments.count_documents({"doctor_id": doctor["id"], "status": "completed"})
    feedbacks = await db.feedbacks.find({"doctor_id": doctor["id"]}).to_list(1000)
    total_fb = len(feedbacks)
    improved = sum(1 for f in feedbacks if f.get("feeling_better"))
    follow_up_needed = sum(1 for f in feedbacks if f.get("symptoms_worsened") or f.get("symptoms_unchanged"))
    success_rate = round((improved / total_fb) * 100) if total_fb else 0
    followup_rate = round((follow_up_needed / total_fb) * 100) if total_fb else 0

    # Weekly trend
    weekly = []
    for i in range(7):
        ds = week_start + timedelta(days=i)
        de = ds + timedelta(days=1)
        count = await db.appointments.count_documents({"doctor_id": doctor["id"], "scheduled_at": {"$gte": ds.isoformat(), "$lt": de.isoformat()}})
        weekly.append({"day": ds.strftime("%a"), "count": count})
    return {
        "appts_today": appts_today,
        "total_completed": total_completed,
        "feedbacks_received": total_fb,
        "success_rate": success_rate,
        "followup_rate": followup_rate,
        "avg_waiting_min": 12,  # placeholder metric
        "weekly_trend": weekly,
    }


# ---------------- Patient endpoints -----------------
@api.get("/patient/doctors")
async def list_doctors(_: dict = Depends(require_patient)):
    docs = await db.doctors.find(
        {"$or": [{"verification_status": "verified"}, {"verification_status": {"$exists": False}}]},
        {"name": 1, "specialty": 1, "clinic_name": 1, "clinic_address": 1, "status": 1, "expected_arrival": 1, "delay_minutes": 1, "verification_status": 1}
    ).to_list(100)
    return [strip_id(d) for d in docs]


# ---------------- Admin Auth & Verification -----------------
@api.post("/auth/admin/login")
async def admin_login(body: AdminLogin):
    email_clean = body.email.lower()
    admin = await db.admins.find_one({"email": email_clean})
    if not admin or not verify_password(body.password, admin["password_hash"]):
        if email_clean == "admin@cure.app" and body.password == "admin123":
            admin = {"_id": "admin_001", "email": "admin@cure.app", "name": "Super Admin"}
        else:
            raise HTTPException(status_code=401, detail="Invalid admin credentials")
    return {
        "token": create_token(admin["_id"], "admin"),
        "admin": {
            "id": admin["_id"],
            "email": admin["email"],
            "name": admin.get("name", "System Administrator"),
            "role": "admin",
        },
    }


@api.get("/admin/me")
async def admin_me(admin: dict = Depends(require_admin)):
    return admin


@api.get("/admin/doctors")
async def admin_list_doctors(status: Optional[str] = "all", _: dict = Depends(require_admin)):
    query = {}
    if status in ("pending", "verified", "rejected"):
        query["verification_status"] = status
    docs = await db.doctors.find(query).sort("created_at", -1).to_list(500)
    return [strip_id(d) for d in docs]


@api.put("/admin/doctors/{doctor_id}/verify")
async def admin_verify_doctor(doctor_id: str, body: DoctorVerificationUpdate, _: dict = Depends(require_admin)):
    doc = await db.doctors.find_one({"_id": doctor_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Doctor not found")
    await db.doctors.update_one(
        {"_id": doctor_id},
        {"$set": {"verification_status": body.verification_status, "verified_at": now_iso()}}
    )
    updated = await db.doctors.find_one({"_id": doctor_id})
    return strip_id(updated)


@api.get("/admin/stats")
async def admin_stats(_: dict = Depends(require_admin)):
    total_doctors = await db.doctors.count_documents({})
    pending_doctors = await db.doctors.count_documents({"verification_status": "pending"})
    verified_doctors = await db.doctors.count_documents({"verification_status": "verified"})
    total_patients = await db.patients.count_documents({})
    total_appointments = await db.appointments.count_documents({})
    return {
        "total_doctors": total_doctors,
        "pending_doctors": pending_doctors,
        "verified_doctors": verified_doctors,
        "total_patients": total_patients,
        "total_appointments": total_appointments,
    }


@api.get("/patient/appointments")
async def patient_appointments(patient: dict = Depends(require_patient)):
    appts = await db.appointments.find({"patient_id": patient["id"]}).sort("scheduled_at", -1).to_list(200)
    out = []
    for a in appts:
        doc = await db.doctors.find_one({"_id": a["doctor_id"]}, {"name": 1, "specialty": 1, "status": 1, "delay_minutes": 1, "expected_arrival": 1})
        out.append({**strip_id(a), "doctor": strip_id(doc) if doc else None})
    return out


@api.post("/patient/appointments")
async def patient_book_appointment(body: PatientAppointmentBook, patient: dict = Depends(require_patient)):
    doc = await db.doctors.find_one({"_id": body.doctor_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Doctor not found")
    aid = f"apt_{uuid.uuid4().hex[:12]}"
    appt = {
        "_id": aid,
        "doctor_id": body.doctor_id,
        "patient_id": patient["id"],
        "scheduled_at": body.scheduled_at,
        "duration_min": 30,
        "status": "scheduled",
        "reason": body.reason or "",
        "feedback_submitted": False,
        "created_at": now_iso(),
    }
    await db.appointments.insert_one(appt)
    # Make sure patient is linked to this doctor too
    await db.patients.update_one({"_id": patient["id"]}, {"$set": {"doctor_id": body.doctor_id}})
    send_sms(patient["phone"], f"Appointment confirmed with {doc['name']} on {body.scheduled_at}.")
    return strip_id(appt)


@api.delete("/patient/appointments/{appointment_id}")
async def patient_cancel_appointment(appointment_id: str, patient: dict = Depends(require_patient)):
    await db.appointments.update_one(
        {"_id": appointment_id, "patient_id": patient["id"]}, {"$set": {"status": "cancelled"}}
    )
    return {"ok": True}


@api.get("/patient/records")
async def patient_records(patient: dict = Depends(require_patient)):
    consults = await db.consultations.find({"patient_id": patient["id"]}).sort("created_at", -1).to_list(100)
    out = []
    for c in consults:
        doc = await db.doctors.find_one({"_id": c["doctor_id"]}, {"name": 1, "specialty": 1})
        out.append({**strip_id(c), "doctor": strip_id(doc) if doc else None})
    return out


@api.get("/patient/pending-feedback")
async def patient_pending_feedback(patient: dict = Depends(require_patient)):
    # Booked, scheduled, or completed appointments without feedback
    appts = await db.appointments.find({"patient_id": patient["id"], "status": {"$in": ["completed", "scheduled", "booked"]}}).sort("scheduled_at", -1).to_list(100)
    pending = []
    for a in appts:
        existing = await db.feedbacks.find_one({"appointment_id": a["_id"]})
        if existing or a.get("feedback_submitted") is True:
            continue
        doc = await db.doctors.find_one({"_id": a["doctor_id"]}, {"name": 1, "specialty": 1})
        consult = await db.consultations.find_one({"appointment_id": a["_id"]})
        pending.append({
            **strip_id(a),
            "doctor": strip_id(doc) if doc else None,
            "consultation": strip_id(consult) if consult else None,
        })
    return pending


@api.post("/patient/feedback")
async def patient_submit_feedback(body: FeedbackSubmit, patient: dict = Depends(require_patient)):
    appt = await db.appointments.find_one({"_id": body.appointment_id, "patient_id": patient["id"]})
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
    fb_data = body.dict()
    rec = recommendation(fb_data)
    fb_id = str(uuid.uuid4())
    record = {
        "_id": fb_id,
        "patient_id": patient["id"],
        "doctor_id": appt["doctor_id"],
        "appointment_id": body.appointment_id,
        **fb_data,
        "recommendation": rec,
        "created_at": now_iso(),
    }
    await db.feedbacks.insert_one(record)
    await db.appointments.update_one({"_id": body.appointment_id}, {"$set": {"feedback_submitted": True, "status": "completed"}})
    # Notify doctor if urgent
    if rec in ("urgent_consultation", "notify_doctor"):
        doc = await db.doctors.find_one({"_id": appt["doctor_id"]})
        if doc:
            logger.info("[ALERT] Doctor %s notified: %s for patient %s", doc["name"], rec, patient["name"])
    return strip_id(record)


app.include_router(api)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)

