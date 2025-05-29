@echo off
echo ======================= >> "D:\frada group\Thinxi\thinxi_log.txt"
echo اجرای فایل بت در: %date% %time% >> "D:\frada group\Thinxi\thinxi_log.txt"
"C:\Users\MHJHA\AppData\Local\Programs\Python\Python311\python.exe" "D:\frada group\Thinxi\THINXI CODES\thinxi\thinxi\generate_questions.py" >> "D:\frada group\Thinxi\thinxi_log.txt" 2>&1
echo پایان اجرا در: %time% >> "D:\frada group\Thinxi\thinxi_log.txt"
pause
