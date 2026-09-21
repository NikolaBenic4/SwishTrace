# DynamoDB Data Model

ShotLab uses one on-demand DynamoDB table.

| Entity | PK | SK |
| --- | --- | --- |
| User profile | `USER#<uid>` | `PROFILE` |
| Session | `USER#<uid>` | `SESSION#<sessionId>` |
| Shot event | `SESSION#<sessionId>` | `SHOT#<shotId>` |
| Friend edge | `USER#<uid>` | `FRIEND#<friendUid>` |
| Current quests | `USER#<uid>` | `QUESTS#CURRENT` |
| Challenge | `CHALLENGE#<id>` | `DETAIL` |
| Leaderboard row | `USER#<uid>` | `LEADERBOARD#<week>` |

`LeaderboardIndex` groups rows under `WEEK#<ISO week>` and sorts descending
points through an inverted, zero-padded score. `EmailIndex` maps normalized
Firebase email addresses to user profiles for friend discovery.

Sessions are idempotent: duplicate session IDs are rejected so retries cannot
award points twice. Detailed shot events are stored separately and can be
disabled later if write volume becomes expensive.
