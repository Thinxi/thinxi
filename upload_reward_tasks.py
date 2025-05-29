import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

reward_tasks = [
    # --- Daily ---
    {"id": "daily_login", "title": "Login today", "description": "Open the app and login today", "reward": 2, "trigger": "login", "type": "daily"},
    {"id": "play_daily_game", "title": "Play a daily game", "description": "Play at least one game today", "reward": 3, "trigger": "game_played", "type": "daily"},
    {"id": "daily_tournament", "title": "Join a tournament", "description": "Play a tournament today", "reward": 5, "trigger": "tournament_played", "type": "daily"},
    {"id": "daily_invite", "title": "Invite a friend", "description": "Invite at least one friend today", "reward": 5, "trigger": "invite_friend", "type": "daily"},
    {"id": "daily_store_visit", "title": "Visit the store", "description": "Open the in-game store", "reward": 1, "trigger": "store_visit", "type": "daily"},
    {"id": "daily_wallet_check", "title": "Check wallet", "description": "Open your wallet today", "reward": 1, "trigger": "wallet_opened", "type": "daily"},
    {"id": "share_score", "title": "Share your score", "description": "Share your score on social media", "reward": 3, "trigger": "shared_score", "type": "daily"},
    {"id": "watch_ad", "title": "Watch a reward ad", "description": "Watch an ad to earn bonus", "reward": 2, "trigger": "ad_watched", "type": "daily"},
    {"id": "daily_correct_10", "title": "Answer 10 questions correctly", "description": "Get 10 correct answers in a day", "reward": 3, "trigger": "correct_10", "type": "daily"},
    {"id": "rate_us", "title": "Rate the app", "description": "Give Thinxi a rating", "reward": 5, "trigger": "app_rated", "type": "daily"},

    # --- Weekly ---
    {"id": "week_streak", "title": "Complete 7-day streak", "description": "Log in and play 7 days in a row", "reward": 20, "trigger": "streak_7days", "type": "weekly"},
    {"id": "win_3_tournaments", "title": "Win 3 tournaments", "description": "Be the winner in 3 tournaments this week", "reward": 15, "trigger": "win_3_tournaments", "type": "weekly"},
    {"id": "invite_3_friends", "title": "Invite 3 friends", "description": "Send 3 invites this week", "reward": 10, "trigger": "invite_3_week", "type": "weekly"},
    {"id": "share_weekly_score", "title": "Share weekly score", "description": "Share your score at the end of the week", "reward": 5, "trigger": "share_weekly", "type": "weekly"},
    {"id": "leaderboard_top100", "title": "Enter Top 100", "description": "Be in top 100 in leaderboard", "reward": 25, "trigger": "leaderboard_100", "type": "weekly"},
    {"id": "answer_300_questions", "title": "Answer 300 questions", "description": "Complete 300 questions this week", "reward": 10, "trigger": "answer_300", "type": "weekly"},
    {"id": "weekly_wallet_topup", "title": "Top up wallet", "description": "Add money to your wallet this week", "reward": 5, "trigger": "wallet_topup", "type": "weekly"},
    {"id": "store_purchase", "title": "Buy from store", "description": "Make a purchase in store", "reward": 5, "trigger": "purchase_store", "type": "weekly"},
    {"id": "video_bonus_weekly", "title": "Watch 5 ads", "description": "Watch 5 ads during the week", "reward": 5, "trigger": "ad_5_week", "type": "weekly"},
    {"id": "update_profile", "title": "Update your profile", "description": "Edit your profile info", "reward": 3, "trigger": "updated_profile", "type": "weekly"},

    # --- Monthly ---
    {"id": "monthly_streak", "title": "Login 30 days", "description": "Stay active every day for a month", "reward": 50, "trigger": "login_30", "type": "monthly"},
    {"id": "monthly_winner", "title": "Win 10 tournaments", "description": "Win 10 tournaments this month", "reward": 30, "trigger": "win_10", "type": "monthly"},
    {"id": "invite_10_friends", "title": "Invite 10 friends", "description": "Bring 10 new friends to Thinxi", "reward": 40, "trigger": "invite_10", "type": "monthly"},
    {"id": "ranked_top10", "title": "Get in top 10", "description": "Enter Top 10 leaderboard", "reward": 50, "trigger": "leaderboard_10", "type": "monthly"},
    {"id": "power_user", "title": "Play 100 games", "description": "Play 100 games this month", "reward": 25, "trigger": "play_100", "type": "monthly"},
    {"id": "big_spender", "title": "Spend in store", "description": "Use your coins or money in store", "reward": 20, "trigger": "store_spent", "type": "monthly"},
    {"id": "watch_20_ads", "title": "Watch 20 videos", "description": "Watch 20 ads this month", "reward": 10, "trigger": "ad_20_month", "type": "monthly"},
    {"id": "earn_100_points", "title": "Earn 100 points", "description": "Earn 100 game points this month", "reward": 20, "trigger": "earned_100", "type": "monthly"},
    {"id": "use_translator", "title": "Use AI Translator", "description": "Translate questions using AI", "reward": 5, "trigger": "used_translator", "type": "monthly"},
    {"id": "monthly_feedback", "title": "Submit feedback", "description": "Send your feedback to Thinxi", "reward": 10, "trigger": "feedback_sent", "type": "monthly"},
]

for task in reward_tasks:
    doc_ref = db.collection("reward_tasks").document()
    doc_ref.set({**task, "active": True})

print("✅ All reward tasks uploaded to Firestore.")
