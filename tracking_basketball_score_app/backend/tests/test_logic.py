import os
import sys
import unittest
from datetime import datetime, timezone

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from logic import calculate_quests, score_for_session, week_key


class LogicTests(unittest.TestCase):
    def test_session_points(self):
        self.assertEqual(score_for_session({"makes": 8, "misses": 2}), 26)

    def test_week_key(self):
        self.assertEqual(
            week_key(datetime(2026, 6, 22, tzinfo=timezone.utc)),
            "2026-W26",
        )

    def test_quest_calculation(self):
        sessions = [
            {
                "endedAt": "2026-06-22T12:00:00Z",
                "makes": 25,
                "misses": 25,
            }
        ]
        quests = calculate_quests(
            sessions,
            now=datetime(2026, 6, 22, 18, tzinfo=timezone.utc),
        )
        self.assertEqual(
            len([quest for quest in quests if quest["type"] == "Daily"]),
            3,
        )
        self.assertEqual(
            len([quest for quest in quests if quest["type"] == "Weekly"]),
            3,
        )
        self.assertEqual(len({quest["id"] for quest in quests}), 6)

    def test_daily_rotation_changes_each_day(self):
        monday = calculate_quests([], now=datetime(2026, 6, 22, tzinfo=timezone.utc))
        tuesday = calculate_quests([], now=datetime(2026, 6, 23, tzinfo=timezone.utc))
        monday_daily = {quest["id"] for quest in monday if quest["type"] == "Daily"}
        tuesday_daily = {quest["id"] for quest in tuesday if quest["type"] == "Daily"}
        monday_weekly = {quest["id"] for quest in monday if quest["type"] == "Weekly"}
        tuesday_weekly = {quest["id"] for quest in tuesday if quest["type"] == "Weekly"}
        self.assertNotEqual(monday_daily, tuesday_daily)
        self.assertEqual(monday_weekly, tuesday_weekly)


if __name__ == "__main__":
    unittest.main()
