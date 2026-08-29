import sys
import asyncio
import unittest
from pathlib import Path

backend_dir = Path(__file__).parent.parent / "backend"
sys.path.insert(0, str(backend_dir))

from server import (
    AdminLogin, DoctorVerificationUpdate,
    admin_login, admin_stats, admin_list_doctors, admin_verify_doctor,
    seed_demo_data, list_doctors
)

class TestAdminFlowDirect(unittest.TestCase):
    def test_admin_flow(self):
        async def run_tests():
            # 1. Seed demo data
            await seed_demo_data()

            # 2. Admin Login
            login_req = AdminLogin(email="admin@cure.app", password="admin123")
            res = await admin_login(login_req)
            self.assertEqual(res["admin"]["role"], "admin")
            admin_user = res["admin"]

            # 3. Get Stats
            stats = await admin_stats(_=admin_user)
            self.assertIn("pending_doctors", stats)
            self.assertIn("verified_doctors", stats)

            # 4. List Pending Doctors
            pending_docs = await admin_list_doctors(status="pending", _=admin_user)
            self.assertGreaterEqual(len(pending_docs), 1)
            pending_doc = next(d for d in pending_docs if d["id"] == "doc_pending_001")
            self.assertEqual(pending_doc["verification_status"], "pending")

            # 5. Verify Pending Doctor
            verify_update = DoctorVerificationUpdate(verification_status="verified")
            verified_doc = await admin_verify_doctor(
                doctor_id=pending_doc["id"],
                body=verify_update,
                _=admin_user
            )
            self.assertEqual(verified_doc["verification_status"], "verified")

            # 6. Verify Patient can now see Doctor
            patient_user = {"id": "pat_demo_001", "name": "John Doe"}
            doctors_for_patient = await list_doctors(_=patient_user)
            doc_ids = [d["id"] for d in doctors_for_patient]
            self.assertIn("doc_pending_001", doc_ids)

            print("\nSUCCESS: All Admin Backend Endpoints Verified Successfully!")

        asyncio.run(run_tests())

if __name__ == "__main__":
    unittest.main()
