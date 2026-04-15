const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const {
  createAction,
  listActions,
  listUserActions,
  cancelAction,
  getUserSummary
} = require('../controllers/governance.controller');

const router = express.Router();

router.use(authMiddleware);

router.get('/governance/users/:id/summary', getUserSummary);

router.get('/admin/governance/actions', listActions);
router.post('/admin/governance/actions', createAction);
router.post('/admin/governance/actions/:id/cancel', cancelAction);
router.get('/admin/governance/users/:id/actions', listUserActions);

module.exports = router;
