const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

const paymentRoute = require("./paymentsRoute");
app.use("/api", paymentRoute);

app.listen(3000, () => {
  console.log("🚀 Server running at http://192.168.1.30:3000");
});
