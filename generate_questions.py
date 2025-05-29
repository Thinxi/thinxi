import requests
import json
import random
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# ✅ مقداردهی Firebase
cred = credentials.Certificate(
    "D:/frada group/Thinxi/THINXI CODES/thinxi/thinxi/thinxi2025-firebase-adminsdk-fbsvc-8ae9172f91.json"
)
firebase_admin.initialize_app(cred)
db = firestore.client()

# ✅ دسته‌بندی سوالات
CATEGORIES = {
    "01": "General Knowledge",
    "02": "Literature & Linguistics",
    "03": "History & Culture",
    "04": "Geography & Countries",
    "05": "Science & Technology",
    "06": "Arts & Cinema",
    "07": "Sports & Games",
    "08": "Pop Culture & Media",
    "09": "Religion & Philosophy",
    "10": "Economy & Business",
    "11": "Everyday Life & Lifestyle",
    "12": "Mythology & Folklore",
    "13": "Brain Teasers & Riddles"
}

# ✅ کلید Gemini API
API_KEY = "AIzaSyCLQvGDIW33kJVG5pSaK3CxRyyQxB_2Ksw"

# ✅ گرفتن شماره سوال بعدی در دسته
def get_next_question_number(category_id):
    questions = db.collection("questions").where("category_id", "==", category_id).stream()
    existing_numbers = [
        int(doc.id.split("-")[1])
        for doc in questions
        if doc.id.startswith(category_id)
    ]
    return str(max(existing_numbers) + 1).zfill(2) if existing_numbers else "01"

# ✅ تعیین سختی بر اساس تعداد سوالات در دسته
def determine_difficulty(category_id):
    questions = db.collection("questions").where("category_id", "==", category_id).stream()
    total = sum(1 for _ in questions)
    next_index = total + 1
    bucket = int((next_index / max(total + 1, 5)) * 5) + 1
    return min(bucket, 5)

# ✅ بررسی تکراری بودن سوال
def is_duplicate(question_text):
    query = db.collection("questions").where("question", "==", question_text).limit(1).stream()
    return any(True for _ in query)

# ✅ تولید سوال جدید با Gemini API
def generate_question():
    category_id, main_category = random.choice(list(CATEGORIES.items()))
    sub_category = main_category
    print(f"📢 تولید سوال برای دسته: {category_id} | {main_category}")

    url = f"https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key={API_KEY}"
    headers = {"Content-Type": "application/json"}
    prompt = f'''
        Generate a unique multiple-choice question (MCQ) about {sub_category}.
        Ensure:
        - The answer choices are diverse and shuffled randomly.
        - The correct answer index is from 0 to 3.
        - Response format (JSON only):
        {{
          "question": "What is the capital of France?",
          "options": ["Paris", "Berlin", "Madrid", "Rome"],
          "correct": 2,
          "category_id": "{category_id}",
          "category": "{main_category}",
          "sub_category": "{sub_category}"
        }}
        Do not repeat previous questions.
    '''

    data = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ]
    }

    print("📤 ارسال درخواست به Gemini API...")
    response = requests.post(url, headers=headers, json=data)

    try:
        response_data = response.json()
        print("✅ پاسخ دریافت شد.")

        if "candidates" not in response_data or not response_data["candidates"]:
            print("❌ خطا: `candidates` خالی است.")
            return None

        raw_text = response_data["candidates"][0]["content"]["parts"][0]["text"]
        clean_json = raw_text.replace("```json\n", "").replace("```", "").strip()
        question_data = json.loads(clean_json)

        if is_duplicate(question_data["question"]):
            print("❌ سوال تکراری بود.")
            return None

        question_data["category_id"] = category_id
        question_data["category"] = main_category
        question_data["sub_category"] = sub_category
        return question_data

    except Exception as e:
        print(f"❌ خطا در پردازش پاسخ: {e}")
        print(f"🔍 پاسخ کامل Gemini:\n{response.text}")
        return None

# ✅ ذخیره سوال در Firestore
def save_question_to_firestore():
    question_data = generate_question()
    if question_data:
        question_number = get_next_question_number(question_data["category_id"])
        now = datetime.now()
        date_part = now.strftime("%Y%m%d")
        time_part = now.strftime("%H%M%S")
        question_id = f"{question_data['category_id']}-{question_number}-{date_part}-{time_part}"

        difficulty = determine_difficulty(question_data["category_id"])
        question_data["difficulty"] = difficulty
        question_data["answer_stats"] = {"correct": 0, "wrong": 0}

        try:
            db.collection("questions").document(question_id).set(question_data)
            print(f"✅ سوال ذخیره شد با ID: {question_id}")
        except Exception as e:
            print(f"❌ خطا در ذخیره‌سازی در Firestore: {e}")

# ✅ ثبت پاسخ کاربر
def record_user_answer(question_id, is_correct):
    doc_ref = db.collection("questions").document(question_id)
    field = "answer_stats.correct" if is_correct else "answer_stats.wrong"
    doc_ref.update({field: firestore.Increment(1)})
    print(f"🟢 پاسخ {'درست' if is_correct else 'غلط'} ثبت شد.")
    adjust_question_difficulty(question_id)

# ✅ تنظیم سختی سوال بر اساس عملکرد کاربران
def adjust_question_difficulty(question_id):
    doc_ref = db.collection("questions").document(question_id)
    doc = doc_ref.get()
    if not doc.exists:
        print(f"❌ سوال با ID {question_id} یافت نشد.")
        return

    data = doc.to_dict()
    stats = data.get("answer_stats", {"correct": 0, "wrong": 0})
    difficulty = data.get("difficulty", 3)

    total_answers = stats["correct"] + stats["wrong"]
    if total_answers < 20:
        return

    accuracy = (stats["correct"] / total_answers) * 100
    new_difficulty = difficulty

    if difficulty >= 3 and accuracy > 51:
        new_difficulty = max(difficulty - 1, 1)
    elif difficulty <= 3 and accuracy < 49:
        new_difficulty = min(difficulty + 1, 5)

    if new_difficulty != difficulty:
        doc_ref.update({"difficulty": new_difficulty})
        print(f"🔁 سختی سوال تغییر کرد: {difficulty} → {new_difficulty}")
    else:
        print("✅ سختی فعلی مناسب است.")

# ✅ اجرای مستقیم
if __name__ == "__main__":
    print("🚀 اجرای تولید سوال آغاز شد...")
    save_question_to_firestore()
