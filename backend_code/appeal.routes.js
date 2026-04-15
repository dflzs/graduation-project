const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const {
  submitAppeal,
  listMyAppeals,
  listAppeals,
  reviewAppeal
} = require('../controllers/appeal.controller');

const router = express.Router();

router.use(authMiddleware);

router.post('/appeals', submitAppeal);
router.get('/appeals/my', listMyAppeals);

router.get('/admin/appeals', listAppeals);
router.post('/admin/appeals/:id/review', reviewAppeal);

module.exports = router;
