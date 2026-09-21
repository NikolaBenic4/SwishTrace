from datetime import datetime, timedelta, timezone


def week_key(timestamp=None):
    current = timestamp or datetime.now(timezone.utc)
    year, week, _ = current.isocalendar()
    return f"{year}-W{week:02d}"


def score_for_session(session):
    makes = int(session.get("makes", 0))
    attempts = int(session.get("attempts", makes + int(session.get("misses", 0))))
    return makes * 2 + attempts


def calculate_quests(sessions, now=None):
    current = now or datetime.now(timezone.utc)
    today = current.date()
    week_start = today - timedelta(days=today.weekday())
    today_sessions = [
        item for item in sessions if _date(item.get("endedAt")) == today
    ]
    week_sessions = [
        item
        for item in sessions
        if week_start <= (_date(item.get("endedAt")) or today) <= today
    ]
    day_seed = (today - datetime(2026, 1, 1).date()).days
    week_seed = (week_start - datetime(2026, 1, 1).date()).days // 7
    return [
        *[
            _build_quest(definition, _stats(today_sessions))
            for definition in _select(DAILY_POOL, day_seed, 3)
        ],
        *[
            _build_quest(definition, _stats(week_sessions))
            for definition in _select(WEEKLY_POOL, week_seed, 3)
        ],
    ]


def _stats(sessions):
    makes = sum(int(item.get("makes", 0)) for item in sessions)
    attempts = sum(
        int(item.get("attempts", int(item.get("makes", 0)) + int(item.get("misses", 0))))
        for item in sessions
    )
    return {
        "makes": makes,
        "attempts": attempts,
        "sessions": len(sessions),
        "minutes": sum(int(item.get("durationSeconds", 0)) for item in sessions) // 60,
        "percentage": round(makes / attempts * 100) if attempts else 0,
        "zones": len({item.get("courtZone") for item in sessions if item.get("courtZone")}),
        "calibratedAttempts": sum(
            int(item.get("attempts", int(item.get("makes", 0)) + int(item.get("misses", 0))))
            for item in sessions
            if item.get("distanceMeters") is not None
        ),
        "timedShots": sum(
            len(item.get("makeFlightTimesMs", []))
            + len(item.get("missFlightTimesMs", []))
            for item in sessions
        ),
    }


def _select(pool, seed, count):
    start = abs(seed) % len(pool)
    return [pool[(start + index * 3) % len(pool)] for index in range(count)]


def _build_quest(definition, stats):
    current = stats[definition["metric"]]
    qualifier_target = definition.get("minimumAttempts")
    qualifier_current = stats["attempts"] if qualifier_target else None
    return {
        "id": definition["id"],
        "type": definition["type"],
        "title": definition["title"],
        "current": current,
        "target": definition["target"],
        "rewardPoints": definition["rewardPoints"],
        "qualifierCurrent": qualifier_current,
        "qualifierTarget": qualifier_target,
        "complete": current >= definition["target"]
        and (qualifier_target is None or qualifier_current >= qualifier_target),
    }


def _date(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00")).date()


DAILY_POOL = [
    {"id": "daily-makes-15", "type": "Daily", "title": "Make 15 shots today", "metric": "makes", "target": 15, "rewardPoints": 70},
    {"id": "daily-attempts-30", "type": "Daily", "title": "Track 30 attempts today", "metric": "attempts", "target": 30, "rewardPoints": 60},
    {"id": "daily-session-1", "type": "Daily", "title": "Complete a tracked session", "metric": "sessions", "target": 1, "rewardPoints": 50},
    {"id": "daily-minutes-15", "type": "Daily", "title": "Train for 15 tracked minutes", "metric": "minutes", "target": 15, "rewardPoints": 80},
    {"id": "daily-accuracy-60", "type": "Daily", "title": "Shoot 60% across 20 attempts", "metric": "percentage", "target": 60, "minimumAttempts": 20, "rewardPoints": 110},
    {"id": "daily-zones-2", "type": "Daily", "title": "Train in 2 court zones", "metric": "zones", "target": 2, "rewardPoints": 90},
    {"id": "daily-calibrated-20", "type": "Daily", "title": "Track 20 shots with distance set", "metric": "calibratedAttempts", "target": 20, "rewardPoints": 85},
    {"id": "daily-timed-12", "type": "Daily", "title": "Capture 12 shot trajectories", "metric": "timedShots", "target": 12, "rewardPoints": 95},
]

WEEKLY_POOL = [
    {"id": "weekly-makes-100", "type": "Weekly", "title": "Make 100 shots this week", "metric": "makes", "target": 100, "rewardPoints": 450},
    {"id": "weekly-attempts-200", "type": "Weekly", "title": "Track 200 attempts this week", "metric": "attempts", "target": 200, "rewardPoints": 400},
    {"id": "weekly-sessions-4", "type": "Weekly", "title": "Complete 4 tracked sessions", "metric": "sessions", "target": 4, "rewardPoints": 500},
    {"id": "weekly-minutes-75", "type": "Weekly", "title": "Train for 75 tracked minutes", "metric": "minutes", "target": 75, "rewardPoints": 550},
    {"id": "weekly-accuracy-65", "type": "Weekly", "title": "Shoot 65% across 75 attempts", "metric": "percentage", "target": 65, "minimumAttempts": 75, "rewardPoints": 700},
    {"id": "weekly-zones-5", "type": "Weekly", "title": "Train in 5 court zones", "metric": "zones", "target": 5, "rewardPoints": 600},
    {"id": "weekly-calibrated-100", "type": "Weekly", "title": "Track 100 shots with distance set", "metric": "calibratedAttempts", "target": 100, "rewardPoints": 575},
    {"id": "weekly-timed-60", "type": "Weekly", "title": "Capture 60 shot trajectories", "metric": "timedShots", "target": 60, "rewardPoints": 625},
]
