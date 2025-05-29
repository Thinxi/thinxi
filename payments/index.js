const functions = require("firebase-functions");
const axios = require("axios");

// 🔐 Cloud Function: ایجاد لینک پرداخت زرین‌پال برای Top-Up والت Thinxi
exports.createZarinpalPayment = functions.https.onCall(async (data, context) => {
  const { amount, userId, description } = data;

  if (!amount || !userId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
  }

  const zarinpalRequest = {
    merchant_id: "5361f89e-f7a9-4158-9cf8-42afadb1febb", // کلید زرین‌پال
    amount: amount * 1000, // زرین‌پال به ریال نیاز دارد
    callback_url: `https://thinxi.com/pay/callback?user=${userId}`,
    description: description || "Thinxi Wallet Top-Up"
  };

  try {
    const response = await axios.post(
      "https://api.zarinpal.com/pg/v4/payment/request.json",
      zarinpalRequest,
      {
        headers: { "Content-Type": "application/json" },
      }
    );

    const { data } = response.data;
    if (data.code === 100) {
      return {
        authority: data.authority,
        link: `https://www.zarinpal.com/pg/StartPay/${data.authority}`,
      };
    } else {
      throw new Error("Zarinpal error code: " + data.code);
    }
  } catch (err) {
    console.error("Zarinpal Error:", err);
    throw new functions.https.HttpsError("internal", "Failed to create payment.");
  }
});
