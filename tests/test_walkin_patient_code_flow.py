import sys
import asyncio
import unittest
from datetime import datetime, timezone
from pathlib import Path

backend_dir = Path(__file__).parent.parent / "backend"
sys.path.insert(0, str(backend_dir))

from server import (
    seed_demo_data, assign_walkin_slot, patient_verify_otp,
    patient_records, doctor_add_consultation,
    WalkinSlotAssign, PatientOTPVerify, ConsultationNoteCreate
)

class TestWalkinPatientCodeFlow(unittest.TestCase):
    def test_walkin_phone_code_and_records_flow(self):
        async def run_test():
            await seed_demo_data()

            staff_user = {
                "id": "staff_01",
                "name": "Clinical Staff",
                "doctor_id": "doc_demo_001",
                "role": "staff"
            }

            doctor_user = {
                "id": "doc_demo_001",
                "name": "Dr. Sarah Smith",
                "role": "doctor"
            }

            walkin_phone = "+919876500099"
            walkin_name = "Walkin Test Patient"

            # 1. Staff adds walkin patient with phone
            walkin_body = WalkinSlotAssign(
                patient_name=walkin_name,
                gender="Female",
                age=27,
                phone=walkin_phone,
            )

            res = await assign_walkin_slot(walkin_body, staff=staff_user)
            self.assertTrue(res["ok"])
            self.assertIn("code", res)
            self.assertEqual(res["code"], "123456")
            self.assertEqual(res["phone"], walkin_phone)
            patient_id = res["patient_id"]
            self.assertTrue(patient_id.startswith("pat_"))

            # 2. Doctor conducts visit and adds consultation note
            consult_body = ConsultationNoteCreate(
                appointment_id=f"appt_{patient_id}",
                patient_id=patient_id,
                diagnosis="Acute Bronchitis",
                prescription="Azithromycin 500mg once daily for 3 days",
                follow_up_instructions="Drink warm water and rest"
            )
            consult_res = await doctor_add_consultation(consult_body, doctor=doctor_user)
            self.assertEqual(consult_res["diagnosis"], "Acute Bronchitis")
            self.assertEqual(consult_res["patient_phone"], walkin_phone)

            # 3. Patient installs app and logs in with phone & OTP code
            otp_body = PatientOTPVerify(phone=walkin_phone, code="123456")
            auth_res = await patient_verify_otp(otp_body)
            self.assertIn("token", auth_res)
            self.assertEqual(auth_res["patient"]["name"], walkin_name)
            self.assertEqual(auth_res["patient"]["phone"], walkin_phone)

            # 4. Patient queries their medical records
            logged_in_patient = {
                "id": auth_res["patient"]["id"],
                "phone": auth_res["patient"]["phone"],
                "name": auth_res["patient"]["name"],
                "role": "patient"
            }
            records = await patient_records(patient=logged_in_patient)
            self.assertGreaterEqual(len(records), 1)
            self.assertEqual(records[0]["diagnosis"], "Acute Bronchitis")
            self.assertEqual(records[0]["prescription"], "Azithromycin 500mg once daily for 3 days")

        asyncio.run(run_test())

if __name__ == "__main__":
    unittest.main()
