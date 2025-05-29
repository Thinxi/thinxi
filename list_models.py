import requests

# 🔥 جایگزین کن با API Key واقعی
API_KEY = "AIzaSyCLQvGDIW33kJVG5pSaK3CxRyyQxB_2Ksw"

url = f"https://generativelanguage.googleapis.com/v1/models?key={API_KEY}"
response = requests.get(url)

print("✅ وضعیت HTTP Response:", response.status_code)
print("✅ متن پاسخ API:")
print(response.text)  # نمایش متن خام پاسخ

try:
    print("✅ لیست مدل‌های فعال:")
    print(response.json())  # نمایش مدل‌ها به‌صورت JSON
except Exception as e:
    print("❌ خطا در پردازش JSON:", e)
