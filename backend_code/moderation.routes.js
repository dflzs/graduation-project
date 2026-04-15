const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const {
  submitRecord,
  listMyRecords,
  getRecordDetail,
  listRecords,
  reviewRecord
} = require('../controllers/moderation.controller');

const router = express.Router();

router.use(authMiddleware);

router.post('/moderation/records', submitRecord);
router.get('/moderation/records/my', listMyRecords);
router.get('/moderation/records/:id', getRecordDetail);

router.get('/admin/moderation/records', listRecords);
router.get('/admin/moderation/records/:id', getRecordDetail);
router.post('/admin/moderation/records/:id/review', reviewRecord);

module.exports = router;
