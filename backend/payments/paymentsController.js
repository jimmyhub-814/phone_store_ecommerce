const axios = require("axios");
const crypto = require("crypto");

class ControllerPayments {

  paymentCod(req, res) {
    return res.json({ message: "COD payment success" });
  }

  async paymentMomo(req, res) {
    try {
      const { amount, orderInfo } = req.body;

      const partnerCode = "MOMO";
      const accessKey = "F8BBA842ECF85";
      const secretKey = "K951B6PE1waDMi640xX8PD3vg6EkVlz";

      const requestId = partnerCode + Date.now();
      const orderId = requestId;
      const redirectUrl = "https://momo.vn/return";
      const ipnUrl = "https://callback.url/notify";
      const requestType = "captureWallet";
      const extraData = "";

      const rawSignature =
        `accessKey=${accessKey}` +
        `&amount=${amount}` +
        `&extraData=${extraData}` +
        `&ipnUrl=${ipnUrl}` +
        `&orderId=${orderId}` +
        `&orderInfo=${orderInfo}` +
        `&partnerCode=${partnerCode}` +
        `&redirectUrl=${redirectUrl}` +
        `&requestId=${requestId}` +
        `&requestType=${requestType}`;

      const signature = crypto
        .createHmac("sha256", secretKey)
        .update(rawSignature)
        .digest("hex");

      const momoRes = await axios.post(
        "https://test-payment.momo.vn/v2/gateway/api/create",
        {
          partnerCode,
          accessKey,
          requestId,
          amount,
          orderId,
          orderInfo,
          redirectUrl,
          ipnUrl,
          extraData,
          requestType,
          signature,
          lang: "vi",
        }
      );

      return res.json(momoRes.data);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

  momoIPN(req, res) {
    console.log("MoMo IPN:", req.body);
    return res.status(204).send();
  }

  momoReturn(req, res) {
    return res.send("MoMo return success");
  }
}

module.exports = new ControllerPayments();
