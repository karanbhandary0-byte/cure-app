import sys
import asyncio
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

backend_dir = Path(__file__).parent.parent / "backend"
sys.path.insert(0, str(backend_dir))

from server import (
    seed_demo_data, doctor_available_slots, add_custom_slot, delete_custom_slot,
    patient_book_appointment, doctor_add_consultation, patient_pending_feedback,
    patient_submit_feedback, doctor_feedbacks, DoctorSettings, update_doctor_settings,
    CustomSlotCreate, PatientAppointmentBook, ConsultationNoteCreate, FeedbackSubmit
)

class TestSlotsAndFeedback(unittest.TestCase):
    def test_slots_and_feedback_flow(self):
        async def run_tests():
            # 1. Seed demo data
            await seed_demo_data()

            doc_user = {"id": "doc_demo_001", "name": "Dr. Sarah Smith", "role": "doctor"}
            pat_user = {"id": "pat_demo_001", "name": "John Doe", "phone": "+15551110001", "role": "patient"}
            tomorrow_date = (datetime.now(timezone.utc) + timedelta(days=1)).strftime("%Y-%m-%d")

            # 2. Test Fetching Slots
            slots_data = await doctor_available_slots("doc_demo_001", date=tomorrow_date, _=pat_user)
            self.assertIn("slots", slots_data)
            self.assertGreater(len(slots_data["slots"]), 0)
            initial_slots_count = len(slots_data["slots"])

            # 3. Test Doctor Adding Custom Extra Slot
            custom_time = (datetime.now(timezone.utc) + timedelta(days=1)).replace(hour=17, minute=0, second=0, microsecond=0).isoformat()
            custom_slot_body = CustomSlotCreate(scheduled_at=custom_time)
            slot_record = await add_custom_slot(custom_slot_body, doctor=doc_user)
            self.assertEqual(slot_record["scheduled_at"], custom_time)
            slot_id = slot_record["id"]

            # Verify extra slot appears in patient slot query
            updated_slots_data = await doctor_available_slots("doc_demo_001", date=tomorrow_date, _=pat_user)
            self.assertEqual(len(updated_slots_data["slots"]), initial_slots_count + 1)

            # 4. Test Patient Booking Slot
            book_body = PatientAppointmentBook(
                doctor_id="doc_demo_001",
                scheduled_at=custom_time,
                reason="Testing slot booking flow"
            )
            appt = await patient_book_appointment(book_body, patient=pat_user)
            self.assertEqual(appt["status"], "scheduled")
            appt_id = appt["id"]

            # Verify booked slot is no longer available
            booked_slots_data = await doctor_available_slots("doc_demo_001", date=tomorrow_date, _=pat_user)
            target_slot = next(s for s in booked_slots_data["slots"] if s["time"] == custom_time)
            self.assertFalse(target_slot["available"])

            # 5. Test Doctor Completing Visit (Adds Consultation Note)
            consult_body = ConsultationNoteCreate(
                appointment_id=appt_id,
                diagnosis="Seasonal Allergy",
                prescription="Cetirizine 10mg daily 5 days",
                follow_up_instructions="Drink water and rest"
            )
            note = await doctor_add_consultation(consult_body, doctor=doc_user)
            self.assertEqual(note["diagnosis"], "Seasonal Allergy")

            # 6. Test Patient Pending Feedback
            pending_list = await patient_pending_feedback(patient=pat_user)
            pending_ids = [p["id"] for p in pending_list]
            self.assertIn(appt_id, pending_ids)

            # 7. Test Patient Submitting Feedback & Triage Engine Recommendation
            fb_body = FeedbackSubmit(
                appointment_id=appt_id,
                feeling_better=True,
                medication_helped=True,
                symptoms_unchanged=False,
                symptoms_worsened=False,
                side_effects="",
                severity=2,
                notes="Felt much better after 2 days!"
            )
            fb_record = await patient_submit_feedback(fb_body, patient=pat_user)
            self.assertEqual(fb_record["recommendation"], "continue_medication")

            # 8. Test Doctor Viewing Feedbacks List
            doc_fbs = await doctor_feedbacks(doctor=doc_user)
            fb_ids = [f["appointment_id"] for f in doc_fbs]
            self.assertIn(appt_id, fb_ids)

            # 9. Test Deleting Custom Slot
            del_res = await delete_custom_slot(slot_id, doctor=doc_user)
            self.assertTrue(del_res["ok"])

            print("\nSUCCESS: All Slot Management and Patient Feedback Workflows Verified 100%!")

            # 10. Test Multi-Session Slot Generation & Validation
            from server import (
                SessionConfig, _validate_sessions, _session_to_minutes, _minutes_to_12hr,
                SlotGenerateRequest, generate_doctor_slots
            )

            # Test 6:00 AM - 8:00 AM (120 min / 4 min = 30 complete slots)
            morning = SessionConfig(
                name="Morning Session",
                start_hour=6,
                start_minute=0,
                start_period="AM",
                end_hour=8,
                end_minute=0,
                end_period="AM",
                consultation_duration_min=4,
            )
            evening = SessionConfig(
                name="Evening Session",
                start_hour=5,
                start_minute=0,
                start_period="PM",
                end_hour=8,
                end_minute=0,
                end_period="PM",
                consultation_duration_min=4,
            )

            is_valid, err = _validate_sessions([morning, evening])
            self.assertTrue(is_valid)

            # Test Overlap Detection
            overlapping_evening = SessionConfig(
                name="Overlap Session",
                start_hour=7,
                start_minute=0,
                start_period="AM",
                end_hour=9,
                end_minute=0,
                end_period="AM",
                consultation_duration_min=4,
            )
            is_valid_overlap, err_overlap = _validate_sessions([morning, overlapping_evening])
            self.assertFalse(is_valid_overlap)
            self.assertIn("Overlapping sessions detected", err_overlap)

            # Test Complete Slot Generation
            gen_res = await generate_doctor_slots(
                SlotGenerateRequest(date="2026-09-03", sessions=[morning, evening]),
                doctor=doc_user
            )
            self.assertEqual(gen_res["total_slots"], 75) # 30 morning + 45 evening
            self.assertEqual(gen_res["slots"][0]["start_time"], "6:00 AM")
            self.assertEqual(gen_res["slots"][0]["end_time"], "6:04 AM")
            self.assertEqual(gen_res["slots"][29]["start_time"], "7:56 AM")
            self.assertEqual(gen_res["slots"][29]["end_time"], "8:00 AM")

        asyncio.run(run_tests())

if __name__ == "__main__":
    unittest.main()

