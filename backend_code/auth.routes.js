const express = require('express');
const {
  sendRegisterCode,
  verifyRegisterCode,
  register,
  loginByPassword,
  me,
  updateMe,
  seedAdmin
} = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/register/code', sendRegisterCode);
router.post('/register/code/verify', verifyRegisterCode);
router.post('/register', register);
router.post('/login/password', loginByPassword);
router.get('/me', authMiddleware, me);
router.put('/me', authMiddleware, updateMe);
router.post('/seed-admin', seedAdmin);

module.exports = router;
