const express = require('express');
const router = express.Router();
const controllerPayments = require('./paymentsController');
console.log('Controller:', controllerPayments);

router.post('/api/payment/cod', controllerPayments.paymentCod);
router.post('/api/payment/momo', controllerPayments.paymentMomo);
router.post('/api/payment/momo/ipn', controllerPayments.momoIPN);
router.get('/api/payment/momo/return', controllerPayments.momoReturn);

module.exports = router;
