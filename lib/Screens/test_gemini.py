import requests

# 🔥 API Key گوگل را اینجا جایگذاری کن
API_KEY = "AIzaSyCLQvGDIW33kJVG5pSaK3CxRyyQxB_2Ksw"

# درخواست تستی برای Gemini API
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateText?key={API_KEY}"
headers = {"Content-Type": "application/json"}
data = {
    "prompt": {"text": "Hello, how are you?"},
    "temperature": 0.7
}

response = requests.post(url, headers=headers, json=data)

# نمایش پاسخ API
print(response.json())
